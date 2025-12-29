{
  lib,
  config,
  ...
}:
lib.mkIf config.services.pipewire.enable {
  services.pipewire.wireplumber.extraConfig = {
    # From: https://wiki.archlinux.org/title/Bluetooth_headset#Disable_PipeWire_HSP/HFP_profile
    #
    # In WirePlumber there's a bug where some applications trigger switching to Headset Profile
    # --
    # See issue #634, #645, #630, #629, #613
    # --
    # This config mitigates the issue by completely disabling the switching and support for
    # Headset Profile (HFP).
    # Using this would only make sense if you never plan on using the microphone that comes with
    # your headset.
    "mitigate-annoying-profile-switch" = {
      # Whether to use headset profile in the presence of an input stream.
      # --
      # Disable for now, as it causes issues. See note at the top as to why.
      "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
      # Enabled roles (default: [ a2dp_sink a2dp_source bap_sink bap_source hfp_hf hfp_ag ])
      #
      # Currently some headsets (Sony WH-1000XM3) are not working with
      # both hsp_ag and hfp_ag enabled, so by default we enable only HFP.
      #
      # Supported roles: hsp_hs (HSP Headset),
      #                  hsp_ag (HSP Audio Gateway),
      #                  hfp_hf (HFP Hands-Free),
      #                  hfp_ag (HFP Audio Gateway)
      #                  a2dp_sink (A2DP Audio Sink)
      #                  a2dp_source (A2DP Audio Source)
      #                  bap_sink (LE Audio Basic Audio Profile Sink)
      #                  bap_source (LE Audio Basic Audio Profile Source)
      # --
      # Only enable A2DP here and disable HFP. See note at the top as to why.
      "monitor.bluez.properties"."bluez5.roles" = [
        "a2dp_sink"
        "a2dp_source"
      ];
    };
    "sink-jabra-elite-85h"."monitor.bluez.rules" = [
      {
        # bump priority a little above the default to make sure it gets selected
        actions.update-props = {
          "priority.driver" = 1100;
          "priority.session" = 1100;
        };
        matches = [
          {
            "media.class" = "Audio/Sink";
            "media.name" = "Jabra Elite 85h";
          }
        ];
      }
    ];
    "sink-yeti-stereo-microphone"."monitor.alsa.rules" = [
      {
        # the default priority was a little over 1100, making it higher than my bluetooth headphones
        actions.update-props = {
          "priority.driver" = 100;
          "priority.session" = 100;
        };
        matches = [
          {
            "media.class" = "Audio/Sink";
            "node.nick" = "Yeti Stereo Microphone";
          }
        ];
      }
    ];
  };
}
