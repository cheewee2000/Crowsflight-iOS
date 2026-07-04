#!/usr/bin/env ruby
# Adds the "Crowsflight Share" share-extension target to Crowsflight.xcodeproj.
# Idempotent: if the target already exists, refreshes its build settings only.
require 'xcodeproj'

project_path = File.expand_path('../Crowsflight.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

# Versions must match the containing app (Crowsflight/Crowsflight-Info.plist:
# CFBundleShortVersionString/CFBundleVersion = 1.8.2), or App Store validation
# rejects the embedded extension.
def apply_build_settings(target)
  target.build_configurations.each do |config|
    s = config.build_settings
    s['PRODUCT_NAME']              = 'CrowsflightShare'
    s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.cwandt.crowsflight.share'
    s['SWIFT_VERSION']             = '5.0'
    s['DEVELOPMENT_TEAM']          = 'L6DVQR8JB9'
    s['CODE_SIGN_STYLE']           = 'Automatic'
    s['CODE_SIGN_ENTITLEMENTS']    = 'CrowsflightShare/CrowsflightShare.entitlements'
    s['INFOPLIST_FILE']            = 'CrowsflightShare/Info.plist'
    s['GENERATE_INFOPLIST_FILE']   = 'NO'
    s['MARKETING_VERSION']         = '1.8.2'
    s['CURRENT_PROJECT_VERSION']   = '1.8.2'
    s['TARGETED_DEVICE_FAMILY']    = '1,2'
    s['SKIP_INSTALL']              = 'YES'
    s['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
  end
end

existing = project.targets.find { |t| t.name == 'Crowsflight Share' }
if existing
  apply_build_settings(existing)
  project.save
  puts 'Crowsflight Share target already exists — build settings refreshed.'
  exit 0
end

app_target = project.targets.find { |t| t.name == 'Crowsflight' }
raise 'Crowsflight app target not found' unless app_target

ext_target = project.new_target(:app_extension, 'Crowsflight Share', :ios, '14.0')
apply_build_settings(ext_target)

# Source files: the view controller + the parser (compiled directly into the
# extension, so no framework/package linkage is needed).
group = project.main_group.new_group('CrowsflightShare', 'CrowsflightShare')
vc_ref = group.new_file('ShareViewController.swift')
group.new_file('Info.plist')
group.new_file('CrowsflightShare.entitlements')

parser_group = project.main_group.new_group('SharedPlacesSources', 'SharedPlaces/Sources/SharedPlaces')
parser_ref = parser_group.new_file('PlaceURLParser.swift')

ext_target.add_file_references([vc_ref, parser_ref])

# Embed the extension in the app.
app_target.add_dependency(ext_target)
embed = app_target.new_copy_files_build_phase('Embed App Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(ext_target.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts 'Added Crowsflight Share target and embedded it in Crowsflight.'
