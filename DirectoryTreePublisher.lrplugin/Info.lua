return {
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'org.cmellum.lightroom.publish.directory_tree',
	LrPluginName = LOC "$$$/DirectoryTreePublisher/PluginName=DirectoryTreePublisher",
	
	LrExportServiceProvider = {
		title = LOC "$$$/DirectoryTreePublisher/Title=DirectoryTreePublisher",
		file = 'DirectoryTreeExportServiceProvider.lua',
	},

	VERSION = { major=12, minor=0, revision=0, build="202210031128-9cb7185d", },
}
