class Present
  class Page
    def initialize(stanza, screen)
      @lines = stanza.split("\n")
      @screen = screen
    end

    def start
      @screen.clear
      stack = [['cap', '']]
      execute_command = proc do
        command, text = stack.pop
        dispatch_command command, text
        @screen.refresh
      end
      @lines.each do |line|
        text, command = line.split(/\s+/, 2).reverse
        if command
          execute_command.call
          stack.push [command, text]
        else
          stack.last[1] += "\n#{text}"
        end
      end
      execute_command.call
    end

  private
    def dispatch_command(command, text)
      case command
      when '='
        @screen.caption text
      when '-'
        @screen.line text
      when '<'
        @screen.line text, :left => 1, :padding => 1
      when '>'
        @screen.line text, :right => 1, :padding => 1
      when /(\++)(\-?)/
        @screen.line '- ' + text, :left => $1.length*2 - 1,
          :padding => $2.empty? ? 1 : 0
      when '*'
        @screen.line text, :row => 1, :bold => true
      when '.'
        @screen.center text.empty? ? "fin" : text, :font => 'mini'
      when '#'
        @screen.center text, :font => 'mini'
      when '%'
        @screen.color *text.split(/\s+/)
      when ','
        @screen.wait text.to_f
      end
    end
  end
end
