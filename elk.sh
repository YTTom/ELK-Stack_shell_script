#!/bin/bash
#Last Modified:20170312
#Writen by JF
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install vim -y

###choose IP address
# /sbin/ifconfig | grep Bcast | awk '{print $2}' | sed 's/addr://' >>ipOfIfconfig.tmp

# declare -i numberOfIp=1
# declare -i count=1
# cat ipOfIfconfig.tmp | while read line
# do
    # echo "$numberOfIp)${line}"
    # ((numberOfIp++))
	# ((count++))
# done

# read -p "Please choose your inet address(IP) which u want to setting (1,2,3...): " iptmp
# declare -i iptmpInt= iptmp
# sed -n '${iptmp}p' ipOfIfconfig.tmp


# ipOfIfconfig.tmp | grep $iptmp | awk '{print $2}' | sed 's/addr://' >> ip.tmp


###choose IP address
/sbin/ifconfig | grep Bcast | awk '{print $2}' | sed 's/addr://'
read -p "Please input your inet address(IP) which u want to setting (xxx.xxx.xxx.xxx): " iptmp      
/sbin/ifconfig | grep $iptmp | awk '{print $2}' | sed 's/addr://' >> ip.tmp
ip=$(<ip.tmp)

while [ "$ip" != "$iptmp" ]
do
        rm ip.tmp
        read -p "Error! Please try again(xxx.xxx.xxx.xxx): " iptmp
		/sbin/ifconfig | grep $iptmp | awk '{print $2}' | sed 's/addr://' >> ip.tmp
		ip=$(<ip.tmp)
done
rm ip.tmp
#echo $ip

###inatall JAVA8
sudo apt-get install -y openjdk-8-jdk
sudo ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/jdk
sed -i '1i export JAVA_HOME=/usr/lib/jvm/jdk/' .bashrc
source .bashrc

###get ip
#touch ip.txt
#/sbin/ifconfig | grep Bcast | awk '{print $2}' | sed 's/addr://' >> ip.txt
#var=$(<ip.txt)

###install elasticsearch
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt-get update -y
sudo apt-get install -y elasticsearch
sudo sed -i 's/#network.host: 192.168.0.1/network.host: '$ip'/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#http.port/http.port/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#cluster.name: my-application/cluster.name: elasticsearch/' /etc/elasticsearch/elasticsearch.yml
sudo service elasticsearch restart
sudo update-rc.d elasticsearch defaults 95 10

###install Logstash
sudo apt-get install -y logstash
sudo touch /etc/logstash/conf.d/first-pipeline.conf
sudo chmod 777 /etc/logstash/conf.d/first-pipeline.conf
echo 'input {' >> /etc/logstash/conf.d/first-pipeline.conf
echo "        beats {" >> /etc/logstash/conf.d/first-pipeline.conf
echo "        port => "5043"" >> /etc/logstash/conf.d/first-pipeline.conf
echo "        }" >> /etc/logstash/conf.d/first-pipeline.conf
echo "}echo" >> /etc/logstash/conf.d/first-pipeline.conf
echo "output {" >> /etc/logstash/conf.d/first-pipeline.conf
echo "  elasticsearch {" >> /etc/logstash/conf.d/first-pipeline.conf
echo "    hosts => \" '$ip':9200\"" >> /etc/logstash/conf.d/first-pipeline.conf
echo "    manage_template => false" >> /etc/logstash/conf.d/first-pipeline.conf
echo "    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"" >> /etc/logstash/conf.d/first-pipeline.conf
echo "    document_type => "%{[@metadata][type]}"" >> /etc/logstash/conf.d/first-pipeline.conf
echo "  }" >> /etc/logstash/conf.d/first-pipeline.conf
echo "}" >> /etc/logstash/conf.d/first-pipeline.conf
sudo service logstash restarts

###install Kibana
sudo apt-get -y install kibana
sudo sed -i 's/#server.port/server.port/' /etc/kibana/kibana.yml
sudo sed -i 's/#server.host: "localhost"/server.host: \"'$ip'\"/' /etc/kibana/kibana.yml
kibana/kibana.yml
sudo sed -i 's/#elasticsearch.url: "http:\/\/localhost:9200"/elasticsearch.url: "http:\/\/'$ip':9200"/' /etc/kibana/kibana.yml
sudo update-rc.d kibana defaults 96 10
sudo service kibana start

###clean extra file
rm ip.txt
