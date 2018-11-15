require_relative 'read_escapes'
# move printing to a separate file

Prob_4 = 0.1
In_terminal = true
Dimensions_xy = [5, 5]

def tint str, num
  return str if num == 0 or not In_terminal
  return "\e[1;#{(41..46).to_a[Math.log(num, 2) % 6]}m#{str}\e[0m" if num > 0
  return "\e[1;#{(101..106).to_a[Math.log(-num, 2) % 6]}m#{str}\e[0m" if num < 0
end

def color num, width
  num_width = num.to_s.length
  num = In_terminal ? num == 0 ? ' ' : num = "\e[#{(91..97).to_a[Math.log(num, 2) % 6]}m#{num}\e[0m" : num.to_s
  ' '*((width - num_width) / 2) + num + ' '*((width - num_width) / 2.0).ceil
end

class Game2048
  def initialize board = nil
    if board
      @board = board.map &:dup
    else
      @board = Dimensions_xy[1].times.map {[0]*Dimensions_xy[0]}
    end
  end
  def add_random! num = 1
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
      value = rand <= Prob_4 ? 4 : 2
      which = zeroes[rand zeroes.length]
      filled_in << zeroes.delete(which)
      @board[which[1]][which[0]] = value
    end
    filled_in
  end
  def move! direction
    mem = @board.map &:dup
    points_returned = 0
    intermediate_animation_boards = nil
    updated_cells = nil
    @board = @board.transpose if ['up', 'down'].include? direction
    @board.map! {|line| line.reverse} if ['down', 'right'].include? direction
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
            updated_cells ||= @board.map {|i| i.map {1}}
            updated_cells[l_index][i] = -1
          end
          next if i == index
          line[i] += cell
          line[index] = 0
        end
      end
    end
    if ['down', 'right'].include? direction
      @board.map! {|line| line.reverse}
      # intermediate boards
      updated_cells.map! {|line| line.reverse} if updated_cells
    end
    if ['up', 'down'].include? direction
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
    s = ''
    puts "\n#{points} points\n#{self.to_s}"
    while alive?
      # check if 2048 exists
      @board.map! {|line| line.map &:abs}
      next_move = ['up', 'down', 'right', 'left', 'exit'][["\e[A", "\e[B", "\e[C", "\e[D", "\u0003"].index read_char]
      next unless next_move
      break if ['quit', 'exit'].include? next_move
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
  def self.to_s board
    m = [board.flatten.map(&:abs).map(&:to_s).map(&:length).max, 4].max
    l = board[0].length
    w = (m + 3) * board[0].length + 1
    board.map {|line|
      '—'*w + "\n" + ([line.map {|v| '|' + tint(' '*(m+2), v)} .join + '|']*2).join("\n#{line.map {|v| '|' + tint((v == 0 ? ' ' : v.abs.to_s).center(m+2), v)} .join + '|'}\n") + "\n"
    } .join + '—'*w
  end
  def to_s
    self.class.to_s @board
  end
end

Game2048.new.play!