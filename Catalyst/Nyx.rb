
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Quark.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -----------------------------------------------------------------

class Nyx

    # Nyx::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx/objects"
    end

    # Nyx::getOrNullAtType(uuid, nyxtype)
    def self.getOrNullAtType(uuid, nyxtype)
        filepath = "#{Nyx::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Nyx::getNyxTypes()
    def self.getNyxTypes()
        Dir.entries(Nyx::pathToRepository())
            .select{|filename| filename[0, 1] != "." }
    end

    # Nyx::destroyAtType(uuid, nyxtype)
    def self.destroyAtType(uuid, nyxtype)
        filepath = "#{Nyx::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------------------------------------------

    # Nyx::objects(nyxtype)
    def self.objects(nyxtype)
        folderpath = "#{Nyx::pathToRepository()}/#{nyxtype}"
        Dir.entries(folderpath)
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{folderpath}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
    end

    # Nyx::getOrNull(uuid)
    def self.getOrNull(uuid)
        Nyx::getNyxTypes()
            .map{|nyxtype| Nyx::getOrNullAtType(uuid, nyxtype) }
            .compact
            .first
    end

    # Nyx::commitToDisk(object)
    def self.commitToDisk(object)
        raise "[02986280]" if object["nyxType"].nil?
        raise "[222C74D4]" if object["uuid"].nil?
        filepath = "#{Nyx::pathToRepository()}/#{object["nyxType"]}/#{object["uuid"]}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
    end

    # Nyx::destroy(uuid)
    def self.destroy(uuid)
        Nyx::getNyxTypes()
            .map{|nyxtype| Nyx::destroyAtType(uuid, nyxtype) }
    end
end
