require 'rubygems'
require 'ncurses'
require 'text'
require 'escape'
require 'nkf'
require 'present/page'

class Present
  VERSION = '0.0.2'
  TIOCGWINSZ = 0x5413

  def initialize(path, timer = 5, page = 1)
    @source = path
    @script = NKF.nkf('-e', open(path).read)
    @stanzas = @script.split(/\n\n+/)
    str = [0, 0, 0, 0].pack("SSSS")
    if $stdin.ioctl(TIOCGWINSZ, str) >= 0 then
      @rows, @cols, xpixels, ypixels = str.unpack("SSSS")
    else
      @rows, @cols = 13, 40
    end
    @pages = @stanzas.map{|stanza| Page.new(stanza, self)}
    @page = page.to_i - 1
    @timer = timer.to_i * 60
  end

  def start
    Ncurses.initscr
    Ncurses.raw
    Ncurses.cbreak
    Ncurses.noecho
    Ncurses.start_color
    Ncurses.refresh
    @win = Ncurses::WINDOW.new @rows - 1, @cols, 0, 0
    @win.keypad true
    Ncurses.nodelay @win, 1
    @status = Ncurses::WINDOW.new 1, @cols + 1, @rows - 1, 0
    @status.color_set 1, nil
    @start = Time.now
    @colors = {}
    register_pair Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE
    while page = @pages[@page]
      @row = @rows / 4
      paginate
      page.start
      
      begin
        input = @win.getch
        case input
        when 27, ?q; return # exit
        when ?:; scan_command
        when ?k, ?h, 259, 260; @page = [@page - 1, 0].max
        when ?<; @page = 0
        when ?>; @page = @pages.size - 1
        when ?j, ?l, 10, 13, 32, 258, 261
          @page = [@page + 1, @pages.size - 1].min
        when ?r; reload
        else
          sleep 0.1
          paginate
        end
      end while input == -1
    end
  ensure
    Ncurses.endwin
  end

  def figlet(font, cols, text)
    font = 'term' if mb?(text)
    cmd = Escape.shell_command(['figlet', '-f', "#{font}.flf", '-w', cols.to_s])
    IO.popen(cmd, 'r+') do |io|
      io.write text
      io.close_write
      io.read
    end
  end

  def reload
    Ncurses.endwin
    exec "#{$0} #{@source} #{@timer/60} #{@page + 1}"
  end

  def center(text, options = {})
    return if text.empty?
    font = options[:font] || 'mini'
    text = figlet font, @cols, text
    rows, cols = sizeof(text)
    top = (@rows - rows)/2
    left = (@cols - cols)/2
    @win.attron Ncurses::A_BOLD
    text = text.split("\n").each_with_index do |line, i|
      mvwprintw top + i, left, line
    end
    @win.attroff Ncurses::A_BOLD
  end

  def caption(text, options = {})
    return if text.empty?
    font = options[:font] || 'mini'
    text = figlet font, @cols, text
    rows, cols = sizeof(text)
    top = (@rows - rows - 2)/2
    left = (@cols - cols)/2
    @win.attron Ncurses::A_BOLD
    text = text.split("\n").each_with_index do |line, i|
      mvwprintw top + i, left, line
    end
    @win.attroff Ncurses::A_BOLD
    @row = top + rows + 1
  end

  def line(text, options = {})
    return @row += 1 if text.empty?
    font = options[:font] || 'term'
    @row = options[:row] if options[:row]
    @row += options[:padding] if options[:padding]
    text = figlet font, @cols, text
    rows, cols = sizeof(text)
    left = options[:left] || (@cols - cols)/2
    left = @cols - cols - options[:right] if right = options[:right]
    @win.attron Ncurses::A_BOLD if options[:bold]
    text = text.split("\n").each_with_index do |line, i|
      mvwprintw @row + i, left, line
    end
    @win.attroff Ncurses::A_BOLD if options[:bold]
    @row += rows + options[:margin].to_i
  end

  def color(front, back = Ncurses::COLOR_BLACK)
    if front =~ /^\d+$/
      pair_id = front.to_i
    elsif front.is_a?(String)
      front = eval "Ncurses::COLOR_#{front.upcase}"
    end
    if back.is_a?(String)
      back = eval "Ncurses::COLOR_#{back.upcase}"
    end
    pair_id ||= register_pair front, back
    @win.color_set pair_id, nil
  end

  def wait(time)
    if time == 0.0
      case input = @status.getch
      when ?j, 32, 10, 13, 27
      else Ncurses.ungetch input
      end
    else
      sleep time
    end
  end

  def sizeof(text)
    lines = text.split("\n")
    cols = lines.map{|line| line.length}.max
    [lines.size, cols]
  end

  def mb?(text)
    text.split(//u).size != text.length
  end

  def paginate
    @status.mvwprintw 0, 0, " " * @cols
    pages = @pages.size
    k = pages.to_s.length
    j = 2 + k*2
    @status.mvwprintw 0, 0, "%#{k}d/%#{k}d|" % [@page + 1, pages]
    cols = @cols - 6 - j
    q = cols % pages
    r = q > 0 ? pages / q : 0
    w = [cols / pages, 1].max
    w += 1 if r > 0 && @page % r == r - 1
    x = (@page*cols + pages/2) / pages
    @status.mvwprintw 0, x + j, "*" * w
    time = Time.now.to_i - @start.to_i
    min, sec = time / 60, time % 60
    @status.mvwprintw 0, cols + j, "|%02d:%02d" % [min, sec]
    @status.refresh
  end

  def scan_command
    @status.mvwprintw 0, 0, " "*@cols
    @status.mvwprintw 0, 0, ':'
    buf = []
    begin
      case input = @status.getch
      when 10, 13; break
      when 27; return nil
      when 127; buf.pop
      else buf << input
      end
      @status.mvwprintw 0, 1, " "*(@cols - 1)
      @status.mvwprintw 0, 1, buf.pack('C*')
      @status.refresh
    end while input > 0
    command, *args = buf.pack('C*').split(/\s+/)
    command = "do_#{command}"
    send command, *args rescue nil if respond_to? command
  end

  def register_pair(front, back)
    key = [front, back]
    return @colors[key] if @colors[key]
    pair_id = @colors.size + 1
    Ncurses.init_pair pair_id, front, back
    @colors[key] = pair_id
  end

  def method_missing(method, *args, &block)
    @win.send method, *args, &block
  end

  def do_go(page)
    @page = [[0, page.to_i - 1].max, @pages.size - 1].min
  end

  def do_sh
    Ncurses.endwin
    system ENV['SHELL'] || 'sh'
    Ncurses.resetty
  end

  def do_q
    exit
  end
end
