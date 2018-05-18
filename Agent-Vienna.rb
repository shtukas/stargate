#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
require_relative "Commons.rb"
# -------------------------------------------------------------------------------------

VIENNA_PATH_TO_DATA = "/Users/pascal/Library/Application Support/Vienna/messages.db"

# select link from messages where read_flag=0;
# update messages set read_flag=1 where link="https://www.schneier.com/blog/archives/2018/04/security_vulner_14.html"

class ViennaLinkFeeder
    def initialize()
        @links = []
    end
    def next()
        if @links.empty? then
            query = "select link from messages where read_flag=0;"
            @links = `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
        end
        @links[0]
    end
    def links()
        @links
    end
    def done(link)
        query = "update messages set read_flag=1 where link=\"#{link}\""
        system("sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'")
        @links.shift
    end
end

$viennaLinkFeeder = ViennaLinkFeeder.new()

# Vienna::processObjectAndCommand(object, command)

class Vienna

    def self.agentuuid()
        "2ba71d5b-f674-4daf-8106-ce213be2fb0e"
    end

    def self.setLinkAsRead(link)

    end

    def self.metric(uuid)
        FIFOQueue::takeWhile(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", lambda{|unixtime| (Time.new.to_i - unixtime)>86400 })
        metric = 0.195 + 0.6*Jupiter::realNumbersToZeroOne($viennaLinkFeeder.links().count, 100, 50)*Math.exp(-FIFOQueue::size(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0").to_f/20) + Jupiter::traceToMetricShift(uuid)
    end

    def self.interface()
        
    end

    def self.generalUpgrade()
        return [] if !Jupiter::isPrimaryComputer()
        link = $viennaLinkFeeder.next()
        return [] if link.nil?
        uuid = Digest::SHA1.hexdigest("cc8c96fe-efa3-4f8a-9f81-5c61f12d6872:#{link}")[0,8]
        object = 
            {
                "uuid" => uuid,
                "agent-uid" => self.agentuuid(),
                "metric" => Vienna::metric(uuid),
                "announce" => "vienna: #{link}",
                "commands" => ['open', 'done'],
                "default-expression" => "open done",
                "item-data" => {
                    "link" => link
                }
            }
        FlockTransformations::removeObjectsFromAgent(self.agentuuid())
        FlockTransformations::addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        if command=='open' then
            system("open '#{object["item-data"]["link"]}'")
        end
        if command=='done' then
            $viennaLinkFeeder.done(object["item-data"]["link"])
            FIFOQueue::push(nil, "timestamps-f0dc-44f8-87d0-f43515e7eba0", Time.new.to_i)
        end
    end
end
