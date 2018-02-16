#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

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

require_relative "Wave.rb"
require_relative "Projects.rb"
require_relative "Timed-Sequences.rb"
require_relative "Ninja.rb"

# ----------------------------------------------------------------------

class CatalystCore
    # CatalystCore::objects()
    def self.objects()
        wl = {}
        wl['uuid'] = SecureRandom.hex
        wl['metric'] = 0.2
        wl['announce'] = "-- Water Level -----------------------------------".green
        wl["commands"] = []
        wl["command-interpreter"] = lambda {|object, command|}

        o1 = WaveInterface::getCatalystObjects()
        o2 = ProjectsInterface::getCatalystObjects()
        o3 = TimedSequences::getCatalystObjects()
        o4 = Ninja::getCatalystObjects()
        
        ([wl]+o1+o2+o3+o4)
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end
end

