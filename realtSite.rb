#!ruby --encoding=cp1251
#coding: UTF-8

require 'open-uri' 
require 'hpricot'
require 'fileutils'
require 'rexml-expansion-fix'
require 'active_record'
require 'action_mailer'
require 'erb'


ActionMailer::Base.smtp_settings = { 
                    :address => "smtp.gmail.com", 
                    :port => 587,#465, 
					:authentication => :plain, 
					:domain => "gmail.com",
					:user_name => "ialexey.kondratenko", 
					:password => 'xxxx',
					:enable_starttls_auto => true
					}

class MaileRealt < ActionMailer::Base
 self.default :from => "ialexey.kondratenko@gmail.com", :charset => "Windows-1251"
 
 def welcom(recipient, textHTML)

	 mail(:to => recipient, :subject => "RealtReport 2 file on the https://github.com/AlexeyAlexey/realt sum in dollars between 0 and 300. \n Worke with scheduler") do |format|	      

         format.html { render :text => textHTML}
     end 
 
 end


 
end

class WrongNumberOfColumnc < StandardError ; end


ActiveRecord::Base.establish_connection("mysql2://")
  
  
class Realt < ActiveRecord::Base
end


class HTMLrealt


  attr_accessor :email

private 
  
   def initialize(urlS, urlQ, valt, сn_min, сn_max, vSps)      
	  
	  @resTable = Array.new #для записи результата
	  @urlSite = proc{ |showNum, pos| "#{urlS}#{urlQ}Cn_min=#{сn_min}&Cn_max=#{сn_max}&TmSdch=#{9999}&srtby=#{5}&showNum=#{showNum}&vSps=#{vSps}&idNp=#{100000}&pos=#{pos}&valt=#{valt}"}
	  
	  htmlHpricot 0, 0

   end

      
   def templetN(arg)
      #print "____________________", Realt.column_names, "\n\n"
      hashTd = Hash.new
	  
	  @nameOfColumns.each {|key| hashTd[key.to_sym] = nil}
	  
	  arrayTd = Array.new
      arg.search(:tr).each do |resTr|
	     i = 1
	     resTr.search(:td).each do |resTd|
		      
		     if i==3
			   then 
			        #проверка на существование первичных ключей
			        if  Realt.where(Street_number: arrayTd[0], district: arrayTd[1]).exists?
                      then 				       
                           arrayTd.clear						   
					       break
                    end		
			 end
			 
			 arrayTd << resTd.inner_html #массив с даными таблицы
			 
			 if i == @countColumn
			   then break			   
			 end
			 			 
		     i += 1
		      
		 end
	     #print "array of td", arrayTd, "\n\n"
		 
		 if !(arrayTd.empty?)
		   then
		     j = 0
		     hashTd.each_key {|key| hashTd[key] = arrayTd[j]; j += 1} #хэш с данными	
             
			 		     		 
			  Realt.create(hashTd) #вставка в базу даных
			 
			  @resTable << arrayTd.clone #передаем массив значений столбцов
		 end
		 
	      arrayTd.clear
	  end
      
   end

   
   def parseTableHTML(htmlHpricot, countOfBox)
      
	  indexBox = 0
	  wr = false
	  arrayBox = Array.new
	  htmlHpricot.search(:tr).each do |resTr|
	  
	        resTr.search(:td).each do |resTd|
			   			   
			   resTd.inner_html #получаем значение ячейки
			   
			   if indexBox == 1
			     then wr = temletSearch(resTd.inner_html, "2") #ещет значение в шаблоне XML "2" - значение атрибута title; resTd.inner_html - текстовое значение; возвращает false or tru  				 
			   end
			   arrayBox[indexBox] = resTd.inner_html #сохраняем ячейки в массиве
			   indexBox += 1 #индекс ячейки
			end
			
			if wr
			  then templetW arrayBox#записываем в XML передавая массив
			end
		    			
	   end
   
   end

   
   def htmlHpricot(showNum, pos)
       	  
	  #print "urlTable @urlSite  :", @urlSite.call(showNum, pos), "\n\n"
      #OpenURI is an easy-to-use wrapper for net/http, net/https and net/ftp.

	  uri = URI.parse @urlSite.call(showNum, pos)
	  @strHtml = uri.read #возвращает html страницу которая сохраняется в str
	  @encodingStr = @strHtml.encoding.name #переменная содержащая кодировку
	  
	 
	  
    Hpricot @strHtml #Используем Hpricot для анализа html  
   end
   
   def searchCnt_all(strHtmlHpr) #находит значение переменной cnt_all которая используется в URI
       
	   countLinStr = "http:\/\/realt\.ua.+(cnt_all=[0-9]+).+"#.encode("Windows-1251")

	   countLinExpr = Regexp.compile countLinStr #Создает регулярное выражение из строки
       	    
	   #Используем Hpricot для анализа html в строке str хранится html страница
	   
	   @cnt_all = 0
	   strHtmlHpr.search(:a).each do |res|
		    
                                    			
			if countLinExpr.match(res.attributes["href"])
			  then @cnt_all = (/([0-9]+)/.match(countLinExpr.match(res.attributes["href"]).to_a[1]).to_a[1]).to_i #обратные ссылки находим количество найденных строк
			end
				
	   end
		
	   
   
   end
 
public

   def catchPage(*titleTableExpr) 
       
	   showNum = 50
	   pos = 0
	   
	   

       searchCnt_all htmlHpricot(showNum, pos)  
   
       		
		#Массив с регулярными выражениями
	   titleTableExpr.map! do |t| 
	        t2=t.encode @encodingStr#изменяем кодировку строки соответствено html
			    Regexp.compile t2 #создаем объект регулярного выражения	   
	   
	   end
		
   
	   countPage = @cnt_all/50 + 1
	   
	   if countPage == 0
	     then countPage = 1
       end
       
	   
	   @nameOfColumns = Realt.column_names #массив с именами полей таблицы базы данных
	   @countColumn = @nameOfColumns.size #количество полей базы данных
	   	   
     titleTable = ["Район города", "Улица, № дома", "Кол-во комнат", "Этаж :Этажность", "Площадь (кв.м) Общ. / Жил./ Кух.", "Цена/Мес." , "Дата"]
     
       	   
	   @resTable << titleTable.map {|el| el.encode @encodingStr}
     
        
        
      #пролистываем страницы
      countPage.times do |countP| 
          
		  pos = countP*50
		  
		 
		 #перебирая параметром pos пролистываем html страницы
	    htmlHpricot(showNum, pos).search(:th).each do |res|
				     
		    if titleTableExpr[1].match(res.inner_html) #res.inner_html - просматривает содержание тега; titleTable[1].match(res.inner_html) - regexpreshion
		      #print "Number page: ", countP, "\n\n\n\n"
			  templetN res.parent.parent #file.write res.parent.parent #вложенность <table> <tr><th></th></tr> </table>
			  #file.write "\n"
			  
			end		
			
	   end
	   
	    
	   
		
       end	


       #Используем ERB для оформления результата
       pathHTMLerb = File.expand_path('../realt.html', __FILE__)
       
       
       fileRealtHTML = File.read pathHTMLerb, encoding: @encodingStr

       erbHTML = ERB.new fileRealtHTML
       
       @email = erbHTML.result binding
     
			
	end
	 

end


htm = HTMLrealt.new("http://realt.ua", "/Db2/0Sd_Kv.php?", 2, 0, 300, 0)

htm.catchPage("[Рр]айон города", "Улица.+", ".+Кол-во.+комнат.+", ".+Этаж :.+")#Ищет таблицу по шапке


MaileRealt.welcom("@gmail.com", htm.email).deliver
