cask "cyndi" do
  version "0.1.0"
  sha256 "b6cac10cbe5175a64cbf882f1069b3d80f59de9438ce2cf22e8bf9425e8f0ef1"

  url "https://github.com/marufahmed-afk/cyndi/releases/download/v#{version}/Cyndi.dmg"
  name "Cyndi"
  desc "Sticky notes that live at the notch"
  homepage "https://github.com/marufahmed-afk/cyndi"

  depends_on macos: ">= :sonoma"

  app "Cyndi.app"

  zap trash: [
    "~/Library/Application Support/Cyndi",
    "~/Library/Preferences/com.marufahmed.cyndi.plist",
  ]
end
