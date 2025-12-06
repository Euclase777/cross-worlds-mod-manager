extends Node

const PROFILES: String = "profiles.json"

var mod_array : Dictionary
var selected_profile = "Default"
var profiles : Dictionary = {"Default":"ModDB.ini",}

signal expand_collapse(tag: String, value:bool, collapse: bool)
