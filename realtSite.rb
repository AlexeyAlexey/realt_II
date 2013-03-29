#!ruby --encoding=cp1251
#coding: UTF-8

require 'open-uri' 
require 'fileutils'
require 'active_record'
require 'action_mailer'
require 'yaml'

Dir.chdir(File.dirname File.expand_path('../realtSite.rb', __FILE__))

ActiveRecord::Base.establish_connection("mysql2://b2de1d2c131a92:ed316f52@us-cdbr-east-03.cleardb.com/heroku_bd8015972428027")
  
class RealtSecond < ActiveRecord::Base
end

ActionMailer::Base.smtp_settings = YAML.load_file('mailer.yaml')

class MaileRealt < ActionMailer::Base
 self.default :from => "ialexey.kondratenko@gmail.com", :charset => "Windows-1251"
 
 def welcom(recipient, msg)

	 mail(:to => recipient, :subject => "RealtReport 2 file on the https://github.com/AlexeyAlexey/realt_II sum in dollars between 0 and 300") do |format|	      
            format.text { render :text => msg}
         end  
 end
 
end


class HTMLrealt

attr_reader :msg

private 
  
   def initialize(urlS, urlQ, valt, сn_min, сn_max, vSps)      
      @msg = ""
      @urlSite = proc{ |showNum, pos| "#{urlS}#{urlQ}Cn_min=#{сn_min}&Cn_max=#{сn_max}&TmSdch=#{9999}&srtby=#{5}&showNum=#{showNum}&vSps=#{vSps}&idNp=#{100000}&pos=#{pos}&valt=#{valt}"}
   end

   
   def str_html(showNum, pos) 
      uri = URI.parse @urlSite.call(showNum, pos)
      uri.read #возвращает html страницу которая сохраняется в str      
   end
   
  
public

   def catchPage(*expr) 
       
      showNum = 50; pos = 0

      refs = expr[1].match str_html(showNum, pos)
      countStr = refs[1].to_i     
      
      countPage = countStr/showNum
	   
      (countPage = 1) if countPage == 0
	
      countPage.times do |pos|
         
         str_html(showNum, pos+1).each_line do |str|
            res = expr[0].match str

            if res
              then                  
                  if !RealtSecond.where(:value_id => res[3]).exists?
                    then 
                        RealtSecond.create(:reference => res[0], :value_id => res[3])                        
                        @msg = " - " + res[0].clone + "\n"                         
                  end                  
            end

         end#str_html       

      end#countPage.times
      (@msg = @msg + "Nothing") if @msg == ""
   end

end

htm = HTMLrealt.new("http://realt.ua", "/Db2/0Sd_Kv.php?", 2, 0, 300, 0)

htm.catchPage(/(http.*)(vid=)(\w*)(\S*\b)/,  /cnt_all=([0-9]*)/)

MaileRealt.welcom("alexey.kondratenko@mail.ru", htm.msg).deliver

