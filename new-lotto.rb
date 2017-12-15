#######################################
####    This script can be used    ####
####    for OZ LOTTO or PowerBall  ####
####    written by: Jason Shen     ####
#######################################


# Game Guide
# Power Ball:           6 in 40 pluse 1 in 20
# OZ Lotto:             7 in 45
# Wensday Lotto:        6 in 45
# Saturday Lotto:       6 in 45

require "json"
require "securerandom"

def loadPoolTemplate
  dir_path = File.dirname File.absolute_path(__FILE__)
  template_name = "dice_rules.json"
  template = File.read File.join dir_path, template_name
  dice_rule = JSON.parse template
  return dice_rule
end

def templateSelect(template)
  today = Time.now
  if today.monday? or today.wednesday? or today.saturday?
      temp_selected = template["monwessat"]
  elsif today.tuesday?
      temp_selected = template["ozlotto"]
  elsif today.thursday?
      temp_selected = template["powerball"]
  else
      #exit
      #temp_selected = template["ozlotto"]
      #temp_selected = template["powerball"]
      temp_selected = template["monwessat"]
  end
  return temp_selected
end

def drawnNumber(range)
    range += 1
    numbers = (SecureRandom.random_number * range).to_i
    return numbers
end

def generateOneGame(template)
  # draw main
  picked_numbers = Array.new
  if template["main"] == template["winning"]
    (1..template["winning"]).each do |x|
       picked_numbers <<  drawnNumber(template["mainpool"])
    end
  else
    # draw main
    (1..template["main"]).each do |x|
      picked_numbers <<  drawnNumber(template["mainpool"])
    end
    # draw supps
    (1..template["supps"]).each do |x|
      supps = drawnNumber(template["suppspool"])
      while picked_numbers.include? supps
        supps = drawnNumber(template["suppspool"])
      end
      #picked_numbers <<  "supps: #{supps}"
      picked_numbers << supps
    end
  end
  return picked_numbers
end

def ratio_check(result, template, draws)
  ratio_main = Hash.new
  (1..template["mainpool"]).each do |x|
     ratio_main["#{x}"] = 0
   end
   result.each do |draw|
     (0..(draw.length - template["supps"] - 1)).each do |num|
       ratio_main[draw[num].to_s] += 1
     end
   end
   #ratio_main.each do |k, v|
     #ratio_main["#{k}"] = ((v.to_f / draws) *100).round(5)
   #end

   if !template["supps"].eql? 0
     ratio_supps = Hash.new
     (1..template["suppspool"]).each do |x|
       ratio_supps["#{x}"] = 0
     end
     result.each do |draw|
       (draw.length - template["supps"]..draw.length - 1).each do |num|
         ratio_supps[draw[num].to_s] += 1
       end
     end
     #ratio_supps.each do |k,v|
       #ratio_supps["#{k}"] = ((v.to_f / draws)*100).round(5)
     #end
   end

   ratio_main_sorted = ratio_main.sort_by(&:last) if ratio_main
   ratio_supps_sorted = ratio_supps.sort_by(&:last) if ratio_supps


   main_5_digits = Array.new
   main_last = Array.new

   (1..template["main"]-1).each do |x|
      main_5_digits << ratio_main_sorted[ratio_main_sorted.length - x][0]
   end
   main_last << ratio_main_sorted[(ratio_main_sorted.length - template["main"])][0]
   i = 1
   while ratio_main_sorted[(ratio_main_sorted.length - template["main"])][1] == ratio_main_sorted[(ratio_main_sorted.length - template["main"] - i)][1]
     main_last << ratio_main_sorted[(ratio_main_sorted.length - template["main"] - i)][0]
     i += 1
   end

   main = Array.new

   i = 0
   main_last.each do |x|
     main[i] = Array.new
     main[i] += main_5_digits
     main[i] += ["#{x}"]
     i += 1
   end
   return main
end

def massiveDraw(template_selected,draw)
  test = Array.new
  (1..draw).each do |x|
    one_draw = generateOneGame(template_selected)
    while one_draw.length != one_draw.uniq.length or one_draw.include? 0
      one_draw = generateOneGame(template_selected)
    end
    test << one_draw
  end
  return test
end

#test.each {|x| puts "#{x}"}
def drawTicket
  template = loadPoolTemplate
  template_selected = templateSelect(template)
  draw = 10000
  test = massiveDraw(template_selected,draw)
  result = ratio_check(test, template_selected, draw)
  puts "#{result}"
  return result
end

ticket = Array.new
(1..5).each do |x|
  drawTicket.each do |draw|
    ticket << draw
  end
end

puts "ticket has #{ticket.length} draws:\n#{ticket}"

path = File.dirname File.absolute_path __FILE__
file = File.read(File.join(path, "index.html.erb"))
ERB.new(@file).result(binding)

Dir.mkdir path + "/site" if !File.directory? path + "/site"
path = File.join path, "site"
Dir.mkdir path + "/history" if !File.directory? path + "/history"
#%x(cp '#{File.join(path, "index.html")}' '#{File.join(path, "/history/index-#@date.html")}') if File.exists?(File.join(path, "index.html"))
File.open(File.join(path, "index.html"), "w") do |f|
  f.write(render)
end