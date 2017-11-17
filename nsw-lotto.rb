#!/home/jason/.rvm/rubies/ruby-2.3.3/bin/ruby
#-*- coding: UTF-8 -*-

#######################################
####    This script can be used    ####
####    for OZ LOTTO or PowerBall  ####
####    written by: Jason Shen     ####
#######################################


# Game Guide
# Power Ball:           6 in 40 pluse 1 in 20
# OZ Lotto:             7 in 45 
# Monday Lotto:         6 in 45
# Wensday Lotto:        6 in 45
# Saturday Lotto:       6 in 45
# The Pools:            6 in 38


require 'optparse'
require 'erb'


class LottoDraw

  def initialize
    @game = 1
    @playtype = 0
    @debug = false
    @pool_main = []
    @pool_supp = []
    @draw_main = 0
    @draw_supp = 0
    @draw_pattern = []
    @draw_result = []
    @main_num_check = Array.new
    @supp_num_check = Array.new
    @lotto_type = ""  
    @sts_main = Array.new(45,0)
    @sts_supp = Array.new
    @path = File.dirname File.absolute_path __FILE__
    @date = Time.now.strftime("%Y-%m-%d-%H-%M-%S")
  end

  def parse_command_line(args)

    opt_parser = OptionParser.new do |opts|

      opts.on("-g", "--game number", "ticket number") do |game|
        @game = game.to_i
      end

      opts.on("-t", "--type number", "game type, 1:powerball, 2: ozlotto, else:monday/wednesday/saturday lotto" ) do |type|
        @playtype = type.to_i
      end
    
      opts.on("-d", "--debug", "debug mode") do |debug|
        @debug = true
      end
    end
    opt_parser.parse(args)
  end

  def high_adjacent_check(numbers)
    hashmap = numbers
    for i in (0..numbers.length-1) 
      puts "test number: #{numbers[i]}" if @debug
      count = 0
      adj_numbers = (numbers[i]+1..numbers[i]+3).to_a
      puts "adj numbers: #{adj_numbers}" if @debug
      adj_numbers.each do |a|
        puts "adj test number: #{a}" if @debug
        if hashmap.include?(a)
          count += 1
        end
      end
      puts "count: #{count}" if @debug
      puts "hashmap: #{hashmap}" if @debug
      if count > 2
        puts "high check return true" if @debug
        return true
      end
    end
    puts "hight check return false" if @debug
    return false
  end

  def low_adjacent_check(numbers)
    hashmap = numbers
    for i in (0..numbers.length-1)
      puts "test number: #{numbers[i]}" if @debug
      count = 0
      adj_numbers = (numbers[i]-3..numbers[i]-1).to_a
      puts "adj numbers: #{adj_numbers}" if @debug
      adj_numbers.each do |a|
        if hashmap.include?(a)
          count += 1
        end
      end
      puts "count: #{count}" if @debug
      puts "hashmap: #{hashmap}" if @debug
      if count > 2
        puts "low check return true" if @debug
        return true
      end
    end
    puts "low check return false" if @debug
    return false
  end
  
  def static_main(result)
    result.flatten!
    result.each { |x| @sts_main[x-1] += 1}
  end

  def static_supp(result)
    @sts_supp[result-1] += 1
  end

  def lotto_type_print
    case @playtype
    when 1 then @lotto_type = "Power Ball"; puts "This is powerball lotto" if @debug
    when 2 then @lotto_type = "OZlotto"; puts "This is OZLotto" if @debug
    else @lotto_type = "Monday Wednesday Saturday Lotto"; puts "This is Monday/Wednesday/Saturday Lotto" if @debug end
  end

  def init_static
    case @playtype
    when 1 then @sts_main=Array.new(40,0);@sts_supp=Array.new(20,0);
    else @sts_main=Array.new(45,0) end
  end

  def sortNumberChance(number)
    number.flatten!
    result = Hash.new
    i = 0
    while i < number.length 
      result["#{number[i]}"] = 0 if !result.has_key?("#{number[i]}") 
      result["#{number[i]}"] += 1
      i += 1
    end
    puts result if @debug
    return result
  end

  def draw_numbers
    main_num_check = Array.new
    supp_num_check = Array.new
    case @playtype
    when 1 then @main_pool = [(1..14).to_a, (15..27).to_a, (28..40).to_a];@supp_pool = (1..20).to_a;@draw_main = 6;@draw_supp = 1;
    when 2 then @main_pool = [(1..15).to_a, (16..30).to_a, (31..45).to_a];@draw_main = 7;
    else @main_pool = [(1..15).to_a, (16..30).to_a, (31..45).to_a];@draw_main = 6;end
    @playtype.eql?(2)?@draw_pattern=[[2,4,1], [1,2,4], [2,1,4], [3,3,1], [1,3,3], [3,1,3], [4,2,1], [1,4,2], [4,1,2]]:@draw_pattern=[[4,1,1],[1,4,1],[1,1,4],[2,3,1],[1,2,3],[2,1,3],[3,2,1],[1,3,2],[3,1,2]]
    puts "main pool: #@main_pool" if @debug
    puts "supp pool: #@supp_pool" if !@supp_pool.nil? and @debug
    puts "draw main: #@draw_main" if @debug
    puts "draw supp: #@draw_supp" if !@draw_supp.eql?(0) and @debug



    pattern_filter = (0..@draw_pattern.length - 1).to_a
    puts "#{pattern_filter}" if @debug
    pattern_index = []
    pattern_draw_number = 1
    while pattern_draw_number < 7 do
      pattern_index.push(pattern_filter.slice!(rand(0..(pattern_filter.length-1))))
      pattern_draw_number += 1
    end
    puts "#{pattern_index}" if @debug
    pattern_index.each do |x|
      @draw_pattern[x] = nil
    end
    @draw_pattern.compact!
    @draw_pattern *= 3



    puts "draw_pattern: #@draw_pattern" if @debug
    @draw_pattern.each do |pattern|
      main_result = []
      supp_result = 0
      pick_num_index = 0
      sub_main_pool = Array.new
      while pick_num_index < pattern.length
        puts "main pool picked index: #{@main_pool[pick_num_index]}" if @debug
        @main_pool[pick_num_index].each {|x| sub_main_pool.push(x)}
        puts "sub main pool: #{sub_main_pool}" if @debug
        p = 0
        while p < pattern[pick_num_index].to_i
          l = sub_main_pool.length
          rand_index = rand(1..(l-p))
          main_result += [sub_main_pool[(rand_index-1)].to_i]
          sub_main_pool[rand_index-1] = sub_main_pool[(l-p-1)]
          p += 1
        end
        pick_num_index += 1
        sub_main_pool = []
      end
        main_result.sort!


      if !@supp_pool.nil?
        supp_result = main_result[-1]
        while main_result.include?(supp_result)
          supp_result = rand(1..@supp_pool.length)
        end
      end
      @draw_result += [main_result]
      @main_num_check += [main_result]
      @supp_num_check += [supp_result] if !@supp_pool.nil?
      @draw_result[-1] += ["Supplementary Number: #{supp_result}"] if !@supp_pool.nil?
      static_main(main_result)
      static_supp(supp_result) if !@supp_pool.nil?
    end
    @draw_result.each {|x| puts "draw result: #{x}"} if @debug
    
  end

  def gettickets
    lotto_type_print
    init_static
    (1..@game).each { draw_numbers }
    @draw_result.each { |x| puts "result: #{x}" } if @debug
  end
 
  def getNumberOdds
    @mainresult = sortNumberChance(@main_num_check) if !@main_num_check.empty?
    @suppresult = sortNumberChance(@supp_num_check) if !@supp_num_check.empty?
   
  end
  def load_html_file
    puts "file path: #@path" if @debug
    @file = File.read(File.join(@path, "index.html.erb"))
    puts @file if @debug
  end

  def render
    load_html_file
    ERB.new(@file).result(binding)
  end

  def output
    Dir.mkdir @path + "/site" if !File.directory?  @path + "/site"
    path = File.join @path, "site"
    %x(cp '#{File.join(path, "index.html")}' '#{File.join(path, "index-#@date.html")}') if File.exists?(File.join(path, "index.html"))
    @date = Time.now
    File.open(File.join(path, "index.html"), "w") do |f|
      f.write(render)
    end
  end
   
end


draw = LottoDraw.new
draw.parse_command_line(ARGV)
draw.gettickets
draw.getNumberOdds
draw.output
