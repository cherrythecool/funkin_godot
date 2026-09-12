extends RefCounted
class_name Song


enum Context {
	FREEPLAY = 0,
	STORY = 1,
	OTHER = 2,
}

var path_name: StringName = &"bopeebo"
var path_difficulty: StringName = &"hard"

var data_chart: Chart = null
var data_metadata: SongMetadata = null
var data_assets: SongAssets = null

var gameplay_context: Context = Context.FREEPLAY
