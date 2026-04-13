cask "noon" do
  version "1.0.0"
  sha256 :no_check # Replace with actual shasum of the DMG

  url "https://github.com/Damien-Esilv/Noon/releases/download/v#{version}/Noon.dmg"
  name "Noon"
  desc "Automated Color Accuracy for Creative Professionals"
  homepage "https://github.com/Damien-Esilv/Noon"

  app "Noon.app"

  uninstall quit: "com.sunazur.Noon"

  zap trash: [
    "~/Library/Application Support/Noon",
    "~/Library/Preferences/com.sunazur.Noon.plist",
  ]
end
