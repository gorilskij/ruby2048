require_relative 'read_escapes'
# TODO: move printing to a separate file

PROB_4 = 0.1
IN_TERMINAL = true
WIDTH = 5
HEIGHT = 5

def tint(str, num)
  if num == 0 or not IN_TERMINAL
    str
  else
    color_code = num < 0 ? 101 + Math.log2(-num).to_i % 6 : 41 + Math.log2(num).to_i % 6
    "\e[1;#{p(color_code)}m#{str}\e[0m"
  end
end

def color(num, width)
  num_width = num.to_s.length
  num = if IN_TERMINAL
          color_code = [*91..97][Math.log(num, 2) % 6]
          num == 0 ? ' ' : "\e[#{color_code}m#{num}\e[0m"
        else
          num.to_s
        end
  ' ' * ((width - num_width) / 2) + num + ' ' * ((width - num_width) / 2.0).ceil
end

class Game2048
  def initialize(board = nil)
    if board
      @board = board.map &:dup
    else
      @board = HEIGHT.times.map { [0] * WIDTH }
    end
  end

  def add_random!(num = 1)
    zeroes = []
    filled_in = []

    @board.each_with_index do |line, y|
      line.each_with_index do |v, x|
        zeroes << [x, y] if v == 0
      end
    end

    num.times do
      if zeroes.length == 0
        puts 'ERROR - tried to insert random 2 or 4 into full board'
        return
      end
      value = rand <= PROB_4 ? 4 : 2
      which = zeroes[rand zeroes.length]
      filled_in << zeroes.delete(which)
      @board[which[1]][which[0]] = value
    end

    filled_in
  end

  def move!(direction)
    mem = @board.map &:dup
    points_returned = 0
    intermediate_animation_boards = nil
    updated_cells = nil
    @board = @board.transpose if %w(up down).include? direction
    @board.map! { |line| line.reverse } if %w(down right).include? direction
    @board.each_with_index do |line, l_index|
      tainted = []
      line[1..-1].each_with_index do |cell, index|
        index += 1
        unless cell == 0
          i = index
          i -= 1 while i > 0 and line[i - 1] == 0
          if i > 0 and line[i - 1] == cell and not tainted.include?(i - 1)
            i -= 1
            tainted << i
            points_returned += cell * 2
            updated_cells ||= @board.map { |row| row.map { 1 } }
            updated_cells[l_index][i] = -1
          end
          next if i == index
          line[i] += cell
          line[index] = 0
        end
      end
    end

    if %w(down right).include? direction
      @board.map! { |line| line.reverse }
      # intermediate boards
      updated_cells.map! { |line| line.reverse } if updated_cells
    end

    if %w(up down).include? direction
      @board = @board.transpose
      # intermediate boards
      updated_cells = updated_cells.transpose if updated_cells
    end

    return nil if mem == @board
    {points: points_returned, boards: intermediate_animation_boards, cells: updated_cells}
    # nil: board hasn't changed
  end

  def alive?
    return true if @board.flatten.include? 0
    [@board, @board.transpose].each do |board|
      board.each do |line|
        line.each_cons 2 do |pair|
          return true if pair[0].abs == pair[1].abs
        end
      end
    end
    false
  end

  def play!
    puts 'u, d, l, r, q to exit'
    add_random!(2).each {|cell_xy| @board[cell_xy[1]][cell_xy[0]] = -@board[cell_xy[1]][cell_xy[0]].abs}
    points = 0

    puts "\n#{points} points\n#{self.to_s}"
    while alive?
      # check if 2048 exists
      @board.map! {|line| line.map &:abs}

      idx = %W(\e[A \e[B \e[C \e[D \u0003).index read_char
      next_move = %w(up down right left exit)[idx]

      next unless next_move
      break if %w(quit exit).include? next_move

      returned = move!(next_move)
      if returned
        points += returned[:points] || 0
        # animate intermediate boards
        new_cell = add_random![0]
        @board[new_cell[1]][new_cell[0]] = -@board[new_cell[1]][new_cell[0]].abs
        @board.map!.with_index {|line, l_index| line.map.with_index {|cell, index| returned[:cells][l_index][index] * cell}} if returned[:cells]
      end
      puts "\n#{points} points\n#{self.to_s}"
    end
    puts alive? ? "DONE (#{points} points)" : "GAME OVER (#{points} points)"
  end

  def self.to_s(board)
    m = [board.flatten.map(&:abs).map(&:to_s).map(&:length).max, 4].max
    l = board[0].length
    w = (m + 3) * board[0].length + 1
    board.map { |line|
      '—' * w
      + "\n"
      # TODO: make readable
      + ([line.map { |v| '|' + tint(' ' * (m + 2), v) }.join + '|'] * 2).join(
          "\n#{line.map { |v| '|' + tint((v == 0 ? ' ' : v.abs.to_s).center(m + 2), v) }.join + '|'}\n"
      )
      + "\n"
    }.join + '—' * w
  end

  def to_s
    self.class.to_s @board
  end
end

Game2048.new.play!