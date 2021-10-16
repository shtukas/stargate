# encoding: UTF-8

class Processes

    # Processes::runFolder(folderpath)
    def self.runFolder(folderpath)
        system("clear")
        puts "[proc] #{File.basename(folderpath)}".green
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue("> Press [enter] to exit folder visit: ")
    end

    # Processes::items(domain)
    def self.items(domain)

        getFileUnixtime = lambda{|filepath|
            unixtime = KeyValueStore::getOrNull(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{filepath}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_i
            KeyValueStore::set(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{filepath}", unixtime)
            unixtime
        }

        getFolderUnixtime = lambda{|folderpath|
            filepath = "#{folderpath}/.unixtime-784971ed"
            if !File.exists?(filepath) then
                File.open(filepath, "w") {|f| f.puts(Time.new.to_f)}
            end
            IO.read(filepath).strip.to_f
        }

        getLocationDomain = lambda {|location|
            d = KeyValueStore::getOrNull(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}")
            return d if d
            puts location.green
            if File.file?(location) then
                puts IO.read(location).strip.green
            end
            d = Domain::interactivelySelectDomain()
            KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", d)
            d
        }

        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Processes")
            .select{|location| getLocationDomain.call(location) == domain }
            .map{|location|
                if File.file?(location) then
                    announce = "[proc] #{IO.read(location).strip}"
                    {
                        "announce"     => announce,
                        "unixtime"     => getFileUnixtime.call(location),
                        "run"          => lambda{},
                    }
                else
                    announce = "[proc] (folder) #{File.basename(location)}"
                    {
                        "announce"     => announce,
                        "unixtime"     => getFolderUnixtime.call(location),
                        "run"          => lambda{ Processes::runFolder(location) },
                    }
                end
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        #{
        #    "announce"
        #    "run"
        #}
    end

    # Processes::ns19s()
    def self.ns19s()
        Processes::items(domain).map{|item|
            {
                "uuid"     => SecureRandom.uuid,
                "announce" => item["announce"],
                "lambda"   => lambda { item["run"].call() }
            }
        }
    end
end
