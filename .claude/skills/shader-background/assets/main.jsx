// Point d'entrée pour site vanilla : compilé en un bundle statique unique.
// Monte le fond dans un div#shader-bg ajouté en tête de <body>.
import React from "react";
import { createRoot } from "react-dom/client";
import { ShaderGradientCanvas, ShaderGradient } from "@shadergradient/react";

function Background() {
  return (
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
  );
}

const host = document.createElement("div");
host.id = "shader-bg";
document.body.prepend(host);
createRoot(host).render(<Background />);
