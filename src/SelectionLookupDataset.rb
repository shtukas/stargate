
# encoding: UTF-8

class SelectionLookupDatabaseIO

    # SelectionLookupDatabaseIO::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Selection-Lookup-Database.sqlite3"
    end

    # SelectionLookupDatabaseIO::removeRecordsAgainstObject(objectuuid)
    def self.removeRecordsAgainstObject(objectuuid)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objectuuid_=?", [objectuuid]
        db.close
    end

    # SelectionLookupDatabaseIO::addRecord(objecttype, objectuuid, fragment)
    def self.addRecord(objecttype, objectuuid, fragment)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
        db.close
    end

    # SelectionLookupDatabaseIO::addRecord2(db, objecttype, objectuuid, fragment)
    def self.addRecord2(db, objecttype, objectuuid, fragment)
        db.execute "insert into lookup (_objecttype_, _objectuuid_, _fragment_) values ( ?, ?, ? )", [objecttype, objectuuid, fragment]
    end

    # SelectionLookupDatabaseIO::updateLookupForDatapoint(datapoint)
    def self.updateLookupForDatapoint(datapoint)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], datapoint["uuid"])
        SelectionLookupDatabaseIO::addRecord("datapoint", datapoint["uuid"], NSNode1638::toString(datapoint).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForTaxonomyItem(taxonomyItem)
    def self.updateLookupForTaxonomyItem(taxonomyItem)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(taxonomyItem["uuid"])
        SelectionLookupDatabaseIO::addRecord("taxonomy_item", taxonomyItem["uuid"], taxonomyItem["uuid"])
        SelectionLookupDatabaseIO::addRecord("taxonomy_item", taxonomyItem["uuid"], Taxonomy::toString(taxonomyItem).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForIsland(island)
    def self.updateLookupForIsland(island)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(islandm["uuid"])
        SelectionLookupDatabaseIO::addRecord("island", island["uuid"], island["uuid"])
        SelectionLookupDatabaseIO::addRecord("island", island["uuid"], Islands::toString(island).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForTag(tag)
    def self.updateLookupForTag(tag)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(tag["uuid"])
        SelectionLookupDatabaseIO::addRecord("tag", tag["uuid"], tag["uuid"])
        SelectionLookupDatabaseIO::addRecord("tag", tag["uuid"], Tags::toString(tag))
    end

    # SelectionLookupDatabaseIO::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], asteroid["uuid"])
        SelectionLookupDatabaseIO::addRecord("asteroid", asteroid["uuid"], Asteroids::toString(asteroid).downcase)
    end

    # SelectionLookupDatabaseIO::updateLookupForWave(wave)
    def self.updateLookupForWave(wave)
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], wave["uuid"])
        SelectionLookupDatabaseIO::addRecord("wave", wave["uuid"], Waves::toString(wave).downcase)
    end

    # SelectionLookupDatabaseIO::getDatabaseRecords(): Array[DatabaseRecord]
    # DatabaseRecord: [objecttype: string, objectuuid: String, fragment: String]
    def self.getDatabaseRecords()
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from lookup" , [] ) do |row|
            answer << {
                "objecttype" => row['_objecttype_'],
                "objectuuid" => row['_objectuuid_'],
                "fragment"   => row['_fragment_'],
            }
        end
        db.close
        answer
    end
end

class SelectionLookupDataset

    # ---------------------------------------------------------

    # SelectionLookupDataset::updateLookupForDatapoint(datapoint)
    def self.updateLookupForDatapoint(datapoint)
        SelectionLookupDatabaseIO::updateLookupForDatapoint(datapoint)
    end

    # SelectionLookupDataset::updateLookupForTaxonomyItem(taxonomyItem)
    def self.updateLookupForTaxonomyItem(taxonomyItem)
        SelectionLookupDatabaseIO::updateLookupForTaxonomyItem(taxonomyItem)
    end

    # SelectionLookupDataset::updateLookupForIsland(island)
    def self.updateLookupForIsland(island)
        SelectionLookupDatabaseIO::updateLookupForIsland(island)
    end

    # SelectionLookupDataset::updateLookupForTag(tag)
    def self.updateLookupForTag(tag)
        SelectionLookupDatabaseIO::updateLookupForTag(tag)
    end

    # SelectionLookupDataset::updateLookupForAsteroid(asteroid)
    def self.updateLookupForAsteroid(asteroid)
        SelectionLookupDatabaseIO::updateLookupForAsteroid(asteroid)
    end

    # ---------------------------------------------------------

    # SelectionLookupDataset::rebuildDatapointsLookup(verbose)
    def self.rebuildDatapointsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["datapoint"]

        NSNode1638::datapoints()
            .each{|datapoint|
                if verbose then
                    puts "datapoint: #{datapoint["uuid"]} , #{NSNode1638::toString(datapoint)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], NSNode1638::toString(datapoint))
                if datapoint["type"] == "NyxFile" then
                    SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["name"])
                end
                if datapoint["type"] == "NyxDirectory" then
                    SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["name"])
                end
                if datapoint["type"] == "NyxFSPoint001" then
                    SelectionLookupDatabaseIO::addRecord2(db, "datapoint", datapoint["uuid"], datapoint["name"])
                end
            }

        db.close
    end

    # SelectionLookupDataset::rebuildTaxonomyItemsLookup(verbose)
    def self.rebuildTaxonomyItemsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["taxonomy_item"]

        Taxonomy::items()
            .each{|taxonomyItem|
                if verbose then
                    puts "taxonomy item: #{taxonomyItem["uuid"]} , #{Taxonomy::toString(taxonomyItem)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "taxonomy_item", taxonomyItem["uuid"], taxonomyItem["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "taxonomy_item", taxonomyItem["uuid"], Taxonomy::toString(taxonomyItem))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildIslandsLookup(verbose)
    def self.rebuildIslandsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["island"]

        Islands::islands()
            .each{|island|
                if verbose then
                    puts "island: #{island["uuid"]} , #{Islands::toString(island)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "island", island["uuid"], island["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "island", island["uuid"], Islands::toString(island))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildTagsLookup(verbose)
    def self.rebuildTagsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["tag"]

        Tags::tags()
            .each{|tag|
                if verbose then
                    puts "tag: #{tag["uuid"]} , #{Tags::toString(tag)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "tag", tag["uuid"], tag["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "tag", tag["uuid"], Tags::toString(tag))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
    def self.rebuildAsteroidsLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["asteroid"]

        Asteroids::asteroids()
            .each{|asteroid|
                if verbose then
                    puts "asteroid: #{asteroid["uuid"]} , #{Asteroids::toString(asteroid)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "asteroid", asteroid["uuid"], asteroid["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "asteroid", asteroid["uuid"], Asteroids::toString(asteroid))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildWavesLookup(verbose)
    def self.rebuildWavesLookup(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup where _objecttype_=?", ["wave"]

        Waves::waves()
            .each{|wave|
                if verbose then
                    puts "wave: #{wave["uuid"]} , #{Waves::toString(wave)}"
                end
                SelectionLookupDatabaseIO::addRecord2(db, "wave", wave["uuid"], wave["uuid"])
                SelectionLookupDatabaseIO::addRecord2(db, "wave", wave["uuid"], Waves::toString(wave))
            }

        db.close
    end

    # SelectionLookupDataset::rebuildDataset(verbose)
    def self.rebuildDataset(verbose)
        db = SQLite3::Database.new(SelectionLookupDatabaseIO::databaseFilepath())
        db.execute "delete from lookup", []
        db.close

        SelectionLookupDataset::rebuildDatapointsLookup(verbose)
        SelectionLookupDataset::rebuildTaxonomyItemsLookup(verbose)
        SelectionLookupDataset::rebuildIslandsLookup(verbose)
        SelectionLookupDataset::rebuildTagsLookup(verbose)
        SelectionLookupDataset::rebuildAsteroidsLookup(verbose)
        SelectionLookupDataset::rebuildWavesLookup(verbose)
    end

    # ---------------------------------------------------------

    # SelectionLookupDataset::patternToDatapoints(pattern)
    def self.patternToDatapoints(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "datapoint" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToTaxonomyItems(pattern)
    def self.patternToTaxonomyItems(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "taxonomy_item" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToIslands(pattern)
    def self.patternToIslands(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "island" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToTags(pattern)
    def self.patternToTags(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "tag" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToAsteroids(pattern)
    def self.patternToAsteroids(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "asteroid" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end

    # SelectionLookupDataset::patternToWaves(pattern)
    def self.patternToWaves(pattern)
        SelectionLookupDatabaseIO::getDatabaseRecords()
            .select{|record| record["objecttype"] == "wave" }
            .select{|record| record["fragment"].downcase.include?(pattern.downcase) }
            .map{|record| NyxObjects2::getOrNull(record["objectuuid"]) }
            .compact
    end
end
