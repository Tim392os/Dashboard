// Fond dégradé animé plein écran — à monter une fois à la racine de l'app.
import { ShaderGradientCanvas, ShaderGradient } from "@shadergradient/react";

export default function Background() {
  return (
    <div style={{ position: "fixed", inset: 0, zIndex: -1, pointerEvents: "none" }}>
      <ShaderGradientCanvas style={{ position: "absolute", inset: 0 }}>
        <ShaderGradient
          control="props"
          type="waterPlane"
          color1="#ff5005"
          color2="#dbba95"
          color3="#d0bce1"
          animate="on"
          uSpeed={0.3}
        />
      </ShaderGradientCanvas>
    </div>
  );
}
