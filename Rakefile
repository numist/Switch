require 'rake/clean'
require 'rake/packagetask'

require_relative 'Scripts/console'

#
# TODO: deliverables should live in INTERMEDIATESDIR until the very last possible moment, when they have been fully verified.
#

XCODE_BUILD_FILTER = "xcpretty -c"
XCODE_TEST_FILTER = "xcpretty -tc"

#
# Constants
#

RELEASE_BRANCHES = ["develop", "master"]

BUILDDIR = File.absolute_path("Build")

INTERMEDIATESDIR = "#{BUILDDIR}/Intermediates"

DERIVEDDATA = "#{INTERMEDIATESDIR}/DerivedData"

#
# Environmental
#

# Switch.xcodeproj
PROJECT = FileList['*.xcodeproj'][0]

# Switch
PRODUCT = PROJECT.slice(0..(PROJECT.index('.') - 1))

def git_branch
  branch = `git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||'`.strip
  if branch == ""
    branch = `git show-ref --head -s --abbrev | head -n1`.strip
  end
  return branch
end

BRANCH = git_branch

#
# Synthesized
#

BRANCH_IS_RELEASE = RELEASE_BRANCHES.include?(BRANCH)

BRANCH_IS_GM = (BRANCH == "master")

DELIVERABLE_ARCHIVE = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.xcarchive")

DELIVERABLE_APP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.app")

DELIVERABLE_ZIP = File.absolute_path("#{BUILDDIR}/#{PRODUCT}.zip")

def formatted_fail(message)
  fail Console.background_red(Console.white(message))
end

def check_ruby_version
  ruby_version = RUBY_VERSION.split('.')
  required_version = '2.0.0'.split('.')
  formatted_fail "#{deliverable_path} wasn't produced!" if ruby_version.count > 3
  (0..(ruby_version.count - 1)).each do |index|
    if ruby_version[index] < required_version[index]
      formatted_fail "Sorry, this Rakefile requires Ruby #{required_version.join('.')} or newer."
    elsif ruby_version[index] > required_version[index]
      break
    end
  end
end
check_ruby_version

# TODO: better way to get homedir here.
CLOBBER.include(FileList["/Users/#{`whoami`.strip}/Library/Developer/Xcode/DerivedData/#{PRODUCT}-*"])
CLOBBER.include(DERIVEDDATA)

CLEAN.include(FileList[BUILDDIR])

XCODEFLAGS = [
  "-workspace \"#{PRODUCT}.xcworkspace\"",
  "-scheme \"#{PRODUCT}\"",
  "-derivedDataPath \"#{DERIVEDDATA}\"",
].join(' ')

#
# Helpers
#

def prettify_xcode_task(task, test=false)
  unless shell_non_fatal("set -e; set -o pipefail; #{task} | #{test ? XCODE_TEST_FILTER : XCODE_BUILD_FILTER}")
     Console.print(Console.background_red(Console.white("Task failed, retrying without filter")))
    shell(task)
  end

end

def run_task(task, args=nil)
  if args.nil?
    Rake::Task[task].invoke
  else
    Rake::Task[task].invoke(args)
  end
end

def verify_codesign(app_path)
  shell "codesign --verify --verbose --deep \"#{app_path}\""
  shell "spctl --assess --verbose=4 --type execute \"#{app_path}\""
end

def verify_deliverable(deliverable_path)
  formatted_fail "#{deliverable_path} wasn't produced!" unless File.exists? deliverable_path
end

def xcode(action)
  run_task DERIVEDDATA
  prettify_xcode_task("xcodebuild #{XCODEFLAGS} #{action}")
end

def shell(action)
  Console.puts(Console.bold(Console.black("#{action}")))
  formatted_fail "Shell command failed: #{action}" unless system(action)
end

def shell_non_fatal(action)
  Console.puts(Console.bold(Console.black("#{action}")))
  return system(action)
end

def echo_step(step)
  Console.puts(Console.bold(Console.black(Console.background_white(step))))
end

#
# Targets
#

directory BUILDDIR
directory DERIVEDDATA
directory INTERMEDIATESDIR

task :default => [:analyze, :test]

task :deps do
  echo_step "Installing/updating dependencies"
  # Rakefile deps
  shell "gem install xcpretty --no-ri --no-rdoc"
  
  # Submodules
  shell "git submodule sync"
  shell "git submodule update --init --recursive"

  # Pods
  shell "gem install cocoapods --no-ri --no-rdoc"
  shell "pod install"
end

# XXX: can these just be tasks dependant on another task with an argument?
task :analyze do
  xcode "analyze"
end

task :build do
  xcode "build"
end

task :clean do
  xcode "clean"
end

task :test => [:build] do
  echo_step("Testing #{PRODUCT}")
  def test_scheme(scheme)
    prettify_xcode_task("xcodebuild -scheme \"#{scheme}\" -workspace \"#{PRODUCT}.xcworkspace\" -derivedDataPath \"#{DERIVEDDATA}\" test", true)
  end

  test_scheme("Switch")
  test_scheme("ReactiveCocoa")
  test_scheme("NNKit")
  test_scheme("Sparkle")
end


 # :archive "Builds #{PRODUCT}.xcarchive in #{BUILDDIR}"
task :archive => [DELIVERABLE_ARCHIVE]
task DELIVERABLE_ARCHIVE => [File.dirname(DELIVERABLE_ARCHIVE)] do
  echo_step("Building archive bundle: #{File.basename(DELIVERABLE_ARCHIVE)}")

  archive_path = DELIVERABLE_ARCHIVE.slice(0..(DELIVERABLE_ARCHIVE.rindex('.') - 1))
  xcode "-archivePath \"#{archive_path}\" archive"
  verify_deliverable DELIVERABLE_ARCHIVE
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_ARCHIVE)}\n"
end

task :app => [DELIVERABLE_APP]
task DELIVERABLE_APP => [DELIVERABLE_ARCHIVE, File.dirname(DELIVERABLE_APP)] do
  echo_step("Building application bundle: #{File.basename(DELIVERABLE_APP)}")
  
  FileUtils.rm_r DELIVERABLE_APP if File.exist? DELIVERABLE_APP
  
  app_path = DELIVERABLE_APP.slice(0..(DELIVERABLE_APP.rindex('.') - 1))
  shell "xcodebuild -exportArchive -exportFormat APP -archivePath \"#{DELIVERABLE_ARCHIVE}\" -exportPath \"#{app_path}\""
  
  verify_deliverable DELIVERABLE_APP

  if shell_non_fatal "codesign --force --deep --sign \"Developer ID\" \"#{DELIVERABLE_APP}\""
    verify_codesign DELIVERABLE_APP
  else
    # If you're reading this message, you probably don't have a Developer ID certificate for signing the app.
    # This is fine if you want to use your own build, but if you're planning on distributing the deliverables you're going to need to get a Developer ID certificate.
    Console.puts ' _____________________________________ '
    Console.puts '/ WARNING: unable to sign app         \\'
    Console.puts '\\ deliverable with Developer ID!      /'
    Console.puts ' ------------------------------------- '
    Console.puts '        \\   ^__^                       '
    Console.puts '         \\  (oo)\\_______               '
    Console.puts '            (__)\\       )\\/\\           '
    Console.puts '                ||----w |              '
    Console.puts '                ||     ||              '
  end
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_APP)}\n"
end

task :zip => [DELIVERABLE_ZIP]
task DELIVERABLE_ZIP => [DELIVERABLE_APP, File.dirname(DELIVERABLE_ZIP), INTERMEDIATESDIR] do
  echo_step("Building zip archive: #{File.basename(DELIVERABLE_ZIP)}")
  
  FileUtils.rm DELIVERABLE_ZIP if File.exist? DELIVERABLE_ZIP
  shell "cd \"#{File.dirname(DELIVERABLE_APP)}\" && zip --symlinks -rq9o \"#{DELIVERABLE_ZIP}\" \"#{File.basename(DELIVERABLE_APP)}\""
  verify_deliverable DELIVERABLE_ZIP
  
  # Verify that zip didn't ruin code signing (this happened to Switch 0.0.6)
  unzipped_app = "#{INTERMEDIATESDIR}/#{File.basename(DELIVERABLE_APP)}"
  FileUtils.rm_r unzipped_app if File.exist? unzipped_app
  shell "cd \"#{INTERMEDIATESDIR}\" && unzip -q \"#{DELIVERABLE_ZIP}\""
  verify_deliverable unzipped_app
  
  # Verify that unzipped app and app deliverable do not differ.
  shell "diff -r \"#{unzipped_app}\" \"#{DELIVERABLE_APP}\""
  
  # XXX: this will fail if the application was not code signed!
  # Verify unzipped application launches successfully.
  shell "open \"#{unzipped_app}\""
  # grep for "[/]Users/foo/bar" to prevent grep from showing up in the list of processes matching the query.
  match = "[#{unzipped_app[0]}]#{unzipped_app[1..-1]}"
  shell "ps auxwww | grep \"#{match}\" | awk '{ print $2; }' | xargs kill"
  
  unless shell_non_fatal "spctl --assess --verbose=4 --type execute \"#{unzipped_app}\""
    Console.puts Console.background_red(Console.white("WARNING: The application bundle inside #{File.basename(DELIVERABLE_ZIP)} is not properly code signed and is not suitable for distribution!"))
  end
  
  # Clean up
  FileUtils.rm_r unzipped_app
  
  Console.puts "Finished: #{Console.green(DELIVERABLE_ZIP)}\n"
end

task :release_ready? do
  formatted_fail "Releases can only be made from branches: #{RELEASE_BRANCHES.inspect}" unless BRANCH_IS_RELEASE

  gst = 'git status -uno --ignore-submodules=untracked'
  formatted_fail "Uncommitted files detected!\n#{`#{gst} --short`}" unless `#{gst} --porcelain | wc -l`.strip == "0"
end

task :release => [:release_ready?, :analyze, :test, :zip] do
  # The zip build step might succeed without a code signature, but a deliverable for release must be signed!
  verify_codesign DELIVERABLE_APP

  hockey_api_token_file = File.open("Secrets-local/Hockey.api_token.asc", "r")
  hockey_api_token = hockey_api_token_file.read
  
  hockey_app_id_file = File.open("Secrets-local/Hockey.app_id.asc", "r")
  hockey_app_id = hockey_app_id_file.read

  # TODO: get SHA from git
  # TODO: release type from BRANCH_IS_GM
  shell("/usr/local/bin/puck -submit=auto -download=true -source_path=\".\" -api_token=\"#{hockey_api_token}\" -app_id=\"#{hockey_app_id}\" \"#{DELIVERABLE_ARCHIVE}\"")
end
