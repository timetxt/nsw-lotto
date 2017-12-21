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
require "erb"
require "net/smtp"

class NSWLott
    def initialize
        @path = File.dirname File.absolute_path(__FILE__)
        @erb_file = "index.html.erb"
        @template_name = "dice_rules.json"
        @date = Time.now
        @lotto_type = ""
        @ticket = Array.new
        @games = 5
    end

    def loadPoolTemplate
        template = File.read File.join @path, @template_name
        dice_rule = JSON.parse template
        return dice_rule
    end

    def templateSelect(template)
        if @date.monday? or @date.wednesday? or @date.saturday?
            temp_selected = template["monwessat"]
        elsif @date.tuesday?
            temp_selected = template["ozlotto"]
        elsif @date.thursday?
            temp_selected = template["powerball"]
        else
            #exit
            temp_selected = template["ozlotto"]
            #temp_selected = template["powerball"]
            #temp_selected = template["monwessat"]
        end
        @lotto_type = temp_selected["type"]
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
        end
        
        #ratio_supps.each do |k, v|
            #ratio_supps["#{k}"] = ((v.to_f / draws)*100).round(5)
        #end

        
        ratio_main_sorted = ratio_main.sort_by(&:last) if ratio_main
        ratio_supps_sorted = ratio_supps.sort_by(&:last) if ratio_supps


        main_digits = Array.new
        main_last_digit = Array.new
        
        (1..template["main"]-1).each do |x|
            main_digits << ratio_main_sorted[ratio_main_sorted.length - x][0]
        end
        
        main_last_digit << ratio_main_sorted[(ratio_main_sorted.length - template["main"])][0]
        
        i = 1
        while ratio_main_sorted[(ratio_main_sorted.length - template["main"])][1] == ratio_main_sorted[(ratio_main_sorted.length - template["main"] - i)][1]
            main_last_digit << ratio_main_sorted[(ratio_main_sorted.length - template["main"] - i)][0]
            i += 1
        end
        

        main = Array.new
        j = 0
        main_last_digit.each do |x|
            main[j] = Array.new
            main[j] += main_digits
            main[j] += ["#{x}"]
            j += 1
        end
        
        if ratio_supps_sorted
            supps_digit = Array.new

            k = 0
            while ratio_supps_sorted[ratio_supps_sorted.length - 1][1].eql? ratio_supps_sorted[ratio_supps_sorted.length - k -1][1]
                supps_digit << ratio_supps_sorted[ratio_supps_sorted.length - k -1][0]
                k += 1
            end
        end

        if supps_digit
            with_supps = Array.new
            main.each do |m|
                with_supps << m
                with_supps << "supps: #{supps_digit[rand(0..supps_digit.length - 1)]}"
                return with_supps
            end
        else
            return main
        end

    end

    def ratio_draw(template_selected,draw)
        ratio_draw = Array.new
        (1..draw).each do |x|
            game = generateOneGame(template_selected)
            while game.length != game.uniq.length or game.include? 0
                game = generateOneGame(template_selected)
            end
            ratio_draw << game
        end
        return ratio_draw
    end
    
    def drawTicket
        template = loadPoolTemplate
        template_selected = templateSelect(template)
        draw = 10000
        test = ratio_draw(template_selected,draw)
        result = ratio_check(test, template_selected, draw)
        puts "#{result}"
        return result
    end

    def generateGames
        (1..@games).each do |game|
            drawTicket.each do |draw|
                @ticket << draw
            end
        end
    end

    def loadERB
        @file = File.read(File.join(@path, @erb_file))
        ERB.new(@file).result(binding)
    end
    
    def outputHTML
        Dir.mkdir @path + "/site" if !File.directory? @path + "/site"
        path = File.join @path, "site"
        Dir.mkdir path + "/history" if !File.directory? path + "/history"
        @date = @date.strftime("%Y-%m-%d-%H-%M-%S")
        %x(cp '#{File.join(path, "index.html")}' '#{File.join(path, "/history/index-#@date.html")}') if File.exists?(File.join(path, "index.html"))
        File.open(File.join(path, "index.html"), "w") do |f|
            f.write(loadERB)
        end
    end
end


class Email

  def loadHtml
    begin 
      path = File.dirname File.absolute_path __FILE__
      folder = "site" 
      directory = File.join path, folder
      if File.exist? directory
        file = File.join directory, "index.html"
        if File.exists? file
          content = File.read(file)
        else
          raise "File #{file} does not exist"
        end
      else
        raise "Folder #{directory} does not exist"
      end
      return content
    rescue => ex
      puts "Script *FAILED*, Cause: #{ex.message}"
    end
  end

  def loadRecipients
    begin
      path = File.dirname File.absolute_path __FILE__
      mailist = "mailist"
      file = File.join path, mailist
      if File.exists? file
        recipients = File.readlines(file)
      else
        raise "File #{file} does not exist" 
      end
      if recipients.empty?
        recipients << "test@example.com"   # change this email address
      else
        recipients.collect! {|x| x.chop}
      end
      return recipients 
    rescue => ex
      puts "Script *FAILED*, Cause: #{ex.message}"
    end
  end
end




new_lotto_ticket = NSWLott.new
new_lotto_ticket.generateGames
new_lotto_ticket.outputHTML



# send report as HTML email, mailist is at './mailist'
newMail = Email.new

html_body = newMail.loadHtml
recipients = newMail.loadRecipients
recipients.each do |recipient|
message = <<MESSAGE_END
From: <lotto@timetxt.com>
To: <#{recipient}>
MIME-Version: 1.0
Content-type: text/html
Subject: Lotto: Lotto Pickup result 

#{html_body}

MESSAGE_END

Net::SMTP.start('localhost') do |smtp|
  smtp.send_message message, 'lotto@timetxt', "#{recipient}"
end
end
   
