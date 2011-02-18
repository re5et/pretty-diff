# This program accepts either two files or two strings
# and using the unix diff command generates useful output
#
#
# Author::    atom smith (http://twitter.com/re5et)
# Copyright:: Copyright (c) 2010 atom smith
# License::   Distributes under the same terms as Ruby

# This module is a namespace that holds everything

module PrettyDiff

  # verify that files exist and then pass them off
  # to PrettyFileDiff::Diff
  def self.files one, two, options = {}
    if File.file?(one) && File.file?(two)
      return Diff.new one, two, options
    else
      raise ArgumentError
    end
  end

  # makes temporary files from the strings so that the
  # diff command can do its work, passes off to PrettyFileDiff::Diff,
  # and then deletes the temproary files
  def self.strings one, two, options = {}
    require 'tempfile'

    file_one = Tempfile.new('fileone')
    file_two = Tempfile.new('filetwo')
    file_one.write(one)
    file_two.write(two)
    file_one.close
    file_two.close

    diff = Diff.new file_one.path, file_two.path, options

    file_one.unlink
    file_two.unlink

    return diff
  end

  # This class does the actual work of running the diff command
  # and has instance methods to turn the results of diff into
  # html, or a string
  class Diff

    attr_reader :lines

    # runs the unix diff command and saves the output to
    # instance varaiable lines
    def initialize one, two, options = {}

      defaults = {
        :remove_signs              => false,
        :remove_leading_file_lines => false,
        :as_list_items             => true,
        :list_style                => 'ul',
        :no_newline_warning        => false,
        :fake_tab                  => 4
      }

      @options = defaults.merge options

      command = "diff -u #{one.to_s} #{two.to_s}"
      @lines = %x(#{command})
    end

    # simply returns lines
    def to_s
      @lines
    end

    # removes +'s and -'s and wraps the changed lines in either
    # ins or del html tags so it can be styles accordingly
    def to_html
      lines = @lines.each_line.map do |line|
        line.chomp!
        unless @options[:no_newline_warning]
          next if line == '\ No newline at end of file'
        end
        if @options[:remove_leading_file_lines]
          if line =~ /\A[\+|-]{3}/
            next
          end
        end
        if line !~ /\A[\+|-]{3}\s/ && line =~ /\A(\+|-)/
          tag = $~[0] == '-' ? 'del' : 'ins'
          line = line.gsub(/\A./, '') if @options[:remove_signs]
          line = "<#{tag}>#{line.gsub(/\s/,'&nbsp;')}</#{tag}>"
        end
        if @options[:fake_tab]
          line = link.gsub(/\t/, '&nbsp;' * @options[:fake_tab])
        end
        if @options[:as_list_items]
          line = "<li#{ " class=\"#{tag}\"" if tag }>#{line}</li>"
        end
      end.join("\n")
      if @options[:list_style]
        lines = "<#{@options[:list_style]} class=\"pretty-diff\">\n#{lines}\n</#{@options[:list_style]}>"
      end
      return lines
    end

  end
end
