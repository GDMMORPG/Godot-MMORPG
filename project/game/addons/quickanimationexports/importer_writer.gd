@tool
class_name ImporterWriter

func write(data: Dictionary) -> String:
    var text: String = ""
    for key: String in data.keys():
        var value: Variant = data[key]
        if value is Dictionary:
            text += write_block(key, value)
        elif value is Array:
            text += write_array(key, value)
        else:
            text += write_string(key, value)
    return text

func write_block(mykey: String, data: Dictionary) -> String:
    var text: String = ""
    text += "[%s]\n" % mykey
    for key: String in data.keys():
        var value: Variant = data[key]
        if value is Dictionary:
            text += write_object(key, value)
        elif value is Array:
            text += write_array(key, value)
        elif value is int or value is float or value is bool:
            text += write_line(key, value)
        elif value is String:
            text += write_string(key, value)
    return text

func write_object(mykey: String, data: Dictionary) -> String:
    var text: String = ""
    text += "%s=%s\n" % [mykey, JSON.stringify(data, "\t")]
    return text

func write_array(mykey: String, data: Array) -> String:
    var text: String = ""
    text += "%s=%s\n" % [mykey, JSON.stringify(data)]
    return text

func write_string(mykey: String, value: Variant) -> String:
    var text: String = ""
    text += "%s=\"%s\"\n" % [mykey, value]
    return text

func write_line(key: String, value: Variant) -> String:
    var text: String = ""
    text += "%s=%s\n" % [key, value]
    return text
