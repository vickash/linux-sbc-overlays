require 'net/http'
require 'uri'

FILE_PREFIX = "rk3568-"
URL_PREFIX  = "https://raw.githubusercontent.com/radxa-pkg/radxa-overlays/refs/heads/main/arch/arm64/boot/dts/rockchip/overlays/rk3568-"
DEST_FOLDER = "/boot/dtb/rockchip/overlay"

# These are all the overlays for the default config in denko-piboard.
overlays = ["pwm8-m0", "pwm9-m0", "i2c3-m0", "spi3-m1-cs0-spidev"]

# URIs and filenames
dts_uris       = overlays.map { |name| URI("#{URL_PREFIX}#{name}.dts") }
dts_filenames  = overlays.map { |name| "#{FILE_PREFIX}#{name}.dts"  }
dtbo_filenames = overlays.map { |name| "#{FILE_PREFIX}#{name}.dtbo" }

dts_uris.each_with_index do |uri, i|
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    # Get and save .dts from GitHub.
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    File.open(dts_filenames[i], 'w') { |f| f.write(response.body) }
  end

  # Compoile into .dtbo and install.
  `dtc -@ -O dtb -o #{dtbo_filenames[i]} #{dts_filenames[i]}`
  `sudo cp #{dtbo_filenames[i]} #{DEST_FOLDER}`
  
  puts "Installed overlay: #{overlays[i]}"
end
