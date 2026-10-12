/*
    Copyright (c) 2024 Josh Britain (jbritain)
    Licensed under a custom non-commercial license.
    See LICENSE for full terms.

     __   __ __   ______   __  __   ______   __           __   __ __   ______   ______   ______   __   __   ______   ______    
    /\ \ / //\ \ /\  ___\ /\ \/\ \ /\  __ \ /\ \         /\ \ / //\ \ /\  == \ /\  == \ /\  __ \ /\ "-.\ \ /\  ___\ /\  ___\   
    \ \ \'/ \ \ \\ \___  \\ \ \_\ \\ \  __ \\ \ \____    \ \ \'/ \ \ \\ \  __< \ \  __< \ \  __ \\ \ \-.  \\ \ \____\ \  __\   
     \ \__|  \ \_\\/\_____\\ \_____\\ \_\ \_\\ \_____\    \ \__|  \ \_\\ \_____\\ \_\ \_\\ \_\ \_\\ \_\\"\_\\ \_____\\ \_____\ 
      \/_/    \/_/ \/_____/ \/_____/ \/_/\/_/ \/_____/     \/_/    \/_/ \/_____/ \/_/ /_/ \/_/\/_/ \/_/ \/_/ \/_____/ \/_____/ 
                                                                                                                        
    
    By jbritain
    https://jbritain.net
                                            
*/

#include "/lib/common.glsl"

#ifdef csh

layout(local_size_x = 1, local_size_y = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

layout(r32ui) uniform uimage3D voxelMap;

#include "/lib/atmosphere/sky/sky.glsl"

void main() {
  vec3 vanillaSkylight = texture(lightmap, vec2(0.0, 1.0)).rgb;

  #ifdef SKYLIGHT_FROM_FORMULA
  // The sky light colour is what the game's lightmap holds at full sky light and no block light.
  // Iris hands over the real texture, but Vitrail's one comes out darker and less blue
  // (shadows, clouds and water lose their blue ambient). Rebuild it with the vanilla formula
  // and use it as a floor, so a correct lightmap is left untouched.
  float sunHeight = worldSunDir.y; // cos of the sun zenith angle (sunPathRotation is 0)
  float skyDarken = clamp(2.0 * sunHeight + 0.2, 0.0, 1.0);
  skyDarken *= 1.0 - rainStrength * 5.0 / 16.0;
  skyDarken *= 1.0 - thunderStrength * 5.0 / 16.0;
  skyDarken = skyDarken * 0.8 + 0.2;

  vec3 formulaSkylight = mix(vec3(skyDarken, skyDarken, 1.0), vec3(1.0), 0.35);
  formulaSkylight *= skyDarken * 0.95 + 0.05;
  // default "Moody" brightness curve, then the slight pull towards grey
  formulaSkylight = mix(formulaSkylight, 1.0 - pow4(1.0 - formulaSkylight), 0.5);
  formulaSkylight = mix(formulaSkylight, vec3(0.75), 0.04);

  vanillaSkylight = max(vanillaSkylight, formulaSkylight);
  #endif

  skylightColor =
    vanillaSkylight *
    mix(vec3(3.0), vec3(0.9, 0.9, 1.0), smoothstep(-0.1, 0.1, worldLightDir.y));
  
  sunlightColor =
    sunPosition == shadowLightPosition
      ? sunIrradiance
      : moonIrradiance;

  #ifdef WORLD_THE_END
  sunlightColor = vec3(0.4, 0.0, 1.0) * endFlashIntensity;
  #endif

  if (isEyeInWater == 1 && sunPosition == shadowLightPosition) {
    sunlightColor *= vec3(1.5, 1.5, 0.5);
  }

  weatherFrameTimeCounter += frameTime * (wetness + thunderStrength) * 2.0;

  // skylightColor = mix(skylightColor, exp(-1.0 * 10 * skylightColor), wetness);
  // sunlightColor = mix(sunlightColor, exp(-1.0 * 10 * sunlightColor), wetness);

}

#endif

#ifdef vsh
void main() {}
#endif

#ifdef fsh
#ifdef ROUGH_SKY_REFLECTIONS
const bool colortex7MipmapEnabled = true;
#endif
void main() {}

#endif
