
class NxNotes

    # NxNotes::getTextOrNull(item)
    def self.getTextOrNull(item)
        item["note"]
    end

    # NxNotes::getText(item)
    def self.getText(item)
        NxNotes::getTextOrNull(item) || ""
    end

    # NxNotes::commit(item, text)
    def self.commit(item, text)
        item["note"] = text
        BladeAdaptation::commitItem(item)
    end

    # NxNotes::toStringSuffix(item)
    def self.toStringSuffix(item)
        text = NxNotes::getTextOrNull(item)
        ( text and text.strip.size > 0 ) ? " (note)".green : ""
    end

    # NxNotes::edit(item)
    def self.edit(item)
        text = NxNotes::getText(item)
        text = CommonUtils::editTextSynchronously(text)
        NxNotes::commit(item, text)
    end
end