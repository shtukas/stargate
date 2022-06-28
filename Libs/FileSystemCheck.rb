
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx111ExitAtFirstFailure(object, nx111, operator)
    def self.fsckNx111ExitAtFirstFailure(object, nx111, operator)
        return if nx111.nil?
        if !Nx111::types().include?(nx111["type"]) then
            puts "object has an incorrect nx111 value type".red
            puts JSON.pretty_generate(object).red
            exit 1
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            if operator.getBlobOrNull(nhash).nil? then
                puts "object, could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit 1
            end
            parts.each{|nhash|
                if operator.getBlobOrNull(nhash).nil? then
                    puts "object".red
                    puts JSON.pretty_generate(object).red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    exit 1
                end
            }
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
            if !status then
                puts "object, could not validate aion-point".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        if nx111["type"] == "unique-string" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            status = File.exists?(location)
            if !status then
                puts "could not find location".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect nx111 value: #{nx111})"
    end

    # FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(item, operator, verbose)
    def self.fsckLibrarianMikuObjectExitAtFirstFailure(item, operator, verbose)

        puts "fsck: #{JSON.pretty_generate(item)}" if verbose

        if item["mikuType"].nil? then
            raise "(error: d24aa0a4-4a42-40aa-81ca-6ead2d3f7fee) item has no mikuType, #{JSON.pretty_generate(item)}" 
        end

        if item["mikuType"] == "Ax1Text" then
            nhash = item["nhash"]
            begin
                operator.readBlobErrorIfNotFound(nhash)
            rescue
                puts "nhash, blob not found".red
                puts JSON.pretty_generate(item).red
                exit 1
            end
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            return
        end

        if item["mikuType"] == "NxBankOp" then
            return
        end

        if item["mikuType"] == "NxCollection" then
            return
        end

        if item["mikuType"] == "NxDataNode" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        if item["mikuType"] == "NxDNSU" then
            return
        end

        if item["mikuType"] == "NxFrame" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        if item["mikuType"] == "NxPerson" then
            return
        end

        if item["mikuType"] == "NxLink" then
            return
        end

        if item["mikuType"] == "NxShip" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        if item["mikuType"] == "NxTask" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        if item["mikuType"] == "NxTimeline" then
            return
        end

        if item["mikuType"] == "TxDated" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        if item["mikuType"] == "TxTaskQueue" then
            return
        end

        if item["mikuType"] == "Wave" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"], operator)
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc) unsupported mikuType: #{item["mikuType"]}"
    end

    # FileSystemCheck::fsck()
    def self.fsck()
        Librarian::objects().each{|item|
            exit if !File.exists?("/Users/pascal/Desktop/Pascal.png")
            next if XCache::getFlag("625ef9cb-9586-4537-97e9-f25daed3bca7:#{JSON.generate(item)}")
            operator = EnergyGridElizabeth.new()
            FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(item, operator, true)
            XCache::setFlag("625ef9cb-9586-4537-97e9-f25daed3bca7:#{JSON.generate(item)}", true)
        }
        puts "fsck completed successfully".green
    end
end
