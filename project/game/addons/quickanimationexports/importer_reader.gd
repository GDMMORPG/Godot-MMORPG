@tool
class_name ImporterReader

enum TOKEN {
    UNKNOWN,
    COMMENT,
    BLOCK,
    KEY_VALUE_STRING,
    KEY_VALUE_NUMBER,
    KEY_VALUE_BOOL,
    KEY_VALUE_ARRAY,
    KEY_VALUE_OBJECT
}

class ImportObject:
    var data: Dictionary[String, Variant] = {}

var indent: int = 0
var previous_block: String = ""
var result: Dictionary[String, Variant] = {}
var current_block: Dictionary = result
var iterable_string: PackedStringArray = []

func parse(text: String) -> Dictionary[String, Variant]:
    var iterable_indx: int = 0
    var iterable_starter: String = ""
    var expected_iterable: String = ""
    for line: String in text.split("\n"):
        if iterable_indx > 0:
            iterable_string.append(line)
            if iterable_starter in line:
                iterable_indx += 1
            if expected_iterable in line:
                iterable_indx -= 1
                if iterable_indx <= 0:
                    if expected_iterable == "}":
                        read_object()
                    elif expected_iterable == "]":
                        read_array()
                    else:
                        #_log("Unknown iterable: %s" % expected_iterable)
                        pass
                    expected_iterable = ""
                    iterable_indx = 0
            continue

        var token: TOKEN = read_line(line)

        var started_iterable: bool = false
        if token == TOKEN.KEY_VALUE_OBJECT:
            expected_iterable = "}"
            iterable_starter = "{"
            iterable_string.append(line)
            iterable_indx = 1
            started_iterable = true
        elif token == TOKEN.KEY_VALUE_ARRAY:
            expected_iterable = "]"
            iterable_starter = "["
            iterable_string.append(line)
            iterable_indx = 1
            started_iterable = true
        
        if started_iterable:
            if expected_iterable in line:
                if expected_iterable == "}":
                    read_object()
                elif expected_iterable == "]":
                    read_array()
                else:
                    #_log("Unknown iterable: %s" % expected_iterable)
                    pass
                expected_iterable = ""
                iterable_indx = 0

    assert(iterable_indx == 0, "Expected iterable to be 0, but got %s" % iterable_indx)
    assert(expected_iterable == "", "Expected iterable to be empty, but got %s" % expected_iterable)

    return result

func read_line(line: String) -> TOKEN:
    line = line.strip_edges()
    if line.is_empty():
        return TOKEN.UNKNOWN
    
    if line.begins_with("#"):
        # Comment.
        #_log("Comment: %s" % line)
        return TOKEN.COMMENT # Ignore comments.
    elif line.begins_with("["):
        # Block.
        #_log("Block: %s" % line)
        read_block(line)
        return TOKEN.BLOCK
    elif line.contains("="):
        # Key.
        var key_value: Array = line.split("=")
        var key: String = key_value[0].strip_edges()

        # Value
        var proto_value: String = key_value[1].strip_edges()
        var value: Variant
        var value_token: TOKEN = TOKEN.UNKNOWN
        match proto_value[0].to_lower():
            "{":
                # Object.
                #_log("Key: %s Value: %s Object" % [key, proto_value])
                return TOKEN.KEY_VALUE_OBJECT
            "[":
                # Array.
                #_log("Key: %s Value: %s Array" % [key, proto_value])
                return TOKEN.KEY_VALUE_ARRAY
            "\"", "'", "`":
                # String.
                value = proto_value
                # Strip the quotes.
                value = value.substr(1, value.length() - 2)
                value_token = TOKEN.KEY_VALUE_STRING
            "t", "f":
                # Bool.
                value = proto_value.to_lower() == "true"
                value_token = TOKEN.KEY_VALUE_BOOL
            _:
                if proto_value.is_valid_int():
                    # Int
                    value = proto_value.to_int()
                    value_token = TOKEN.KEY_VALUE_NUMBER
                elif proto_value.is_valid_float():
                    # Float
                    value = proto_value.to_float()
                    value_token = TOKEN.KEY_VALUE_NUMBER
                else:
                    #_log("Unknown value type: %" % proto_value[0])
                    return TOKEN.UNKNOWN
        #_log("Key: %s Value: %s Type: %s" % [key, value, value_token])
        current_block[key] = value
        return value_token
    return TOKEN.UNKNOWN

func read_object() -> void:
    #_log("--------------OBJECT---------------")
    var joined_string: String = "\n".join(iterable_string)
    #_log("Reading Object: %s" % joined_string)

    var split: PackedStringArray = joined_string.split("=", true, 1)
    var key = split[0].strip_edges()
    var proto_value: String = split[1].strip_edges()
    var json: Dictionary = JSON.parse_string(proto_value)
    #_log("Readed Object: %s" % JSON.stringify(json, "\t"))
    iterable_string.clear()

    current_block[key] = json
    #_log("--------------OBJECT - END ---------------")

func read_array() -> void:
    var joined_string: String = "\n".join(iterable_string)
    #_log("---------------ARRAY---------------")
    #_log("Reading Array: %s " % joined_string)
    
    var split: PackedStringArray = joined_string.split("=", true, 1)
    #print("Split: %s" % split)
    var key = split[0].strip_edges()
    var proto_value: String = split[1].strip_edges()
    #_log("\nKey: %s\nValue: %s" % [key, proto_value])

    var json: Array = JSON.parse_string(proto_value)
    #_log("Readed Array: %s" % json)

    #_log("---------------ARRAY - END ---------------")

    iterable_string.clear()

    current_block[key] = json

func read_block(line: String) -> void:
    line = line.strip_edges()
    line = line.replace("[", "")
    line = line.replace("]", "")
    line = line.strip_edges()
    previous_block = line
    var blocks: Array = line.split(".")
    current_block = result
    for block: String in blocks:
        if not current_block.has(block):
            current_block[block] = {}
        current_block = current_block[block]

func _log(text: Variant) -> void:
    # print("[Import Reader:LOG] :: %s %s" % ["\t".repeat(indent), text])
    pass
