#!/usr/bin/env ruby
require 'optparse'
require 'pathname'

srcroot = Pathname.new(File.expand_path(File.dirname(__FILE__) + '/..'))
project = srcroot + 'DGSPhone.xcodeproj'
workspace = project + 'project.xcworkspace'
scheme = 'DGS'
app_name = 'DGSBeta'
display_name = 'DGS Beta'
signing_profile = 'iPhone Distribution'
archive_root = Pathname.new(File.expand_path("~/Library/Developer/Xcode/Archives/"))
buildmanifest = srcroot + "vendor/Hockey/client/iOS/Beta Automatisation/buildmanifest.sh"

opts = OptionParser.new do |opts|
  opts.banner = "Usage: build_adhoc.rb [options] server-path"

  opts.on("-h", "--help", "Show this message") do |h|
    puts opts
    exit
  end

  # Opts for provisioning profile, changelog, etc?
  
end

opts.parse!

if ARGV.length != 1
  puts "Error: You must specify the path on the server to upload the files to!"
  puts opts
  exit 1
end

# Build & Archive
system("xcodebuild -workspace #{workspace} -scheme #{scheme} archive")

# Find the .app in the newest built archive
archives_today = archive_root + Time.now.strftime("%Y-%m-%d")
app_archive = archives_today + `ls -t #{archive_root}/#{Time.now.strftime("%Y-%m-%d")}`.split("\n")[0]
app_location = app_archive + "Products/Applications/#{app_name}.app"

# Package the app to /tmp/app_name.ipa
system("/usr/bin/xcrun -sdk iphoneos PackageApplication -v '#{app_location}' -o '/tmp/#{app_name}.ipa'")

info_plist = app_location + "Info"

# Build .plist
system("bundleDisplayName='#{display_name}' '#{buildmanifest}' '#{info_plist}' /tmp/#{app_name}.plist")

bundle_identifier = `defaults read "#{info_plist}" CFBundleIdentifier`.chomp

# Upload files
system("rsync -a /tmp/#{app_name}.* '#{ARGV[0]}/#{bundle_identifier}'")
