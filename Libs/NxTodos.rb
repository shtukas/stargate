
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTodos::isOrphan(item)
    def self.isOrphan(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil?
    end

    # NxTodos::toString(item, context = nil)
    def self.toString(item, context = nil)

        if NxTodos::isOrphan(item) then
            if item["hours-1432"] then
                activity = item["hours-1432"] ? " (#{"%5.2f" % NxThreads::listingRatio(item)} of daily #{"%5.2f" % item["hours-1432"]})".green : "                       "
                positioning = item["hours-1432"] ? "         " : "(#{"%7.3f" % (item["global-positioning"] || 0)})"
                return "#{positioning} #{NxTodos::icon(item)}#{activity} #{item["description"]}"
            end
            return "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)}                        #{item["description"]}"
        end

        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}"
    end

    # NxTodos::orphans()
    def self.orphans()
        # Return the todos 
        Cubes2::mikuType("NxTodo")
            .select{|item| NxTodos::isOrphan(item) }
            .sort_by{|item| item["unixtime"] }
    end

    # ------------------
    # Ops

    # NxTodos::access(item)
    def self.access(item)
        TxPayload::access(item)
    end

    # NxTodos::access(item)
    def self.natural(item)
        NxTodos::access(item)
    end

    # NxTodos::done(item)
    def self.done(item)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
            Cubes2::destroy(item["uuid"])
        end
    end

    # NxTodos::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxTodo")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "c1ec1949-5e0d-44ae-acb2-36429e9146c0") # Misc Timecore
            }

        Cubes2::mikuType("NxTodo")
            .each{|item|
                next if item["parentuuid-0032"].nil?
                parent = Cubes2::itemOrNull(item["parentuuid-0032"])
                next if parent.nil?
                next if parent["mikuType"] == "NxThread"
                Cubes2::setAttribute(item["uuid"], "hours-1432", nil) # we uset active if the parent wasn't an orbital
            }
    end
end
