
$stdout.sync = true

class Console
  @@line_length = 0
  
  def self.append(text)
    # TODO blow up if "\r" is found or something
    text_without_colors = text.gsub(/\e\[[\d]+(;[\d]+)*m/, "")
    last_newline_index = text_without_colors.rindex "\n"
    if last_newline_index.nil?
      @@line_length += text.length
    else
      @@line_length = text.length - (last_newline_index + 1)
    end
  
    $stdout.print text
  end

  def self.clear_line
    # clear the old line
    if @@line_length > 0
      spaces = ""
      @@line_length.times { spaces = "#{spaces} " }
      $stdout.print "\r#{spaces}\r"
      @@line_length = 0
    end
  end

  def self.print(text)
    clear_line
    append text
  end
  
  def self.puts(text)
    print "#{text}\n"
  end

  # Colours:
  # 0	Turn off all attributes
  # 1	Set bright mode
  # 4	Set underline mode
  # 5	Set blink mode
  # 7	Exchange foreground and background colors
  # 8	Hide text (foreground color would be the same as background)
  # 30	Black text
  # 31	Red text
  # 32	Green text
  # 33	Yellow text
  # 34	Blue text
  # 35	Magenta text
  # 36	Cyan text
  # 37	White text
  # 39	Default text color
  # 40	Black background
  # 41	Red background
  # 42	Green background
  # 43	Yellow background
  # 44	Blue background
  # 45	Magenta background
  # 46	Cyan background
  # 47	White background
  # 49	Default background color

  def self.bold(text)
    return "\e[1m#{text}\e[0m"
  end

  def self.cyan(text)
    return "\e[36m#{text}\e[39m"
  end

  def self.black(text)
    return "\e[30m#{text}\e[39m"
  end
  
  def self.green(text)
    return "\e[32m#{text}\e[39m"
  end
end
