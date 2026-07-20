// SPDX-License-Identifier: MS-PL
// Ad hoc diagnostic (not wired into CMakeLists.txt / not a permanent test): draws a real,
// multi-triangle, depth-tested scene through the SOFTWARE (CPU rasterizer) backend and saves the
// resulting backbuffer to a real PNG file on disk -- proving a real screenshot can be produced in
// a headless container with no DISPLAY, no X11, and no GPU at all.

#include "Microsoft/Xna/Framework/Game.hpp"
#include "Microsoft/Xna/Framework/GraphicsDeviceManager.hpp"
#include "Microsoft/Xna/Framework/Color.hpp"
#include "Microsoft/Xna/Framework/Vector3.hpp"
#include "Microsoft/Xna/Framework/Graphics/BasicEffect.hpp"
#include "Microsoft/Xna/Framework/Graphics/GraphicsDevice.hpp"
#include "Microsoft/Xna/Framework/Graphics/PrimitiveType.hpp"
#include "Microsoft/Xna/Framework/Graphics/RasterizerState.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexBuffer.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexPositionColor.hpp"

#include "../examples/common/ScreenshotEXT.hpp"

#include <cstdio>
#include <memory>

using namespace Microsoft::Xna::Framework;
using namespace Microsoft::Xna::Framework::Graphics;

class ScreenshotDemo : public Game
{
    std::unique_ptr<GraphicsDeviceManager> gdm_;

protected:
    void Draw(const GameTime&) override
    {
        auto& dev = getGraphicsDeviceProperty();
        dev.setRasterizerStateProperty(RasterizerState::CullNone);
        dev.Clear(Color(30, 30, 60, 255), 1.0f);

        BasicEffect fx(dev);
        fx.VertexColorEnabled = true;
        fx.Apply();

        // Triangle 1: far, big, blue-ish -- background mountain shape.
        {
            const VertexPositionColor verts[3] = {
                { Vector3(-1.0f, -0.2f, 0.8f), Color(40, 60, 160, 255) },
                { Vector3( 0.0f,  0.9f, 0.8f), Color(90, 120, 220, 255) },
                { Vector3( 1.0f, -0.2f, 0.8f), Color(40, 60, 160, 255) },
            };
            VertexBuffer vb(dev, 3);
            vb.SetData(verts, 3);
            dev.SetVertexBuffer(&vb);
            dev.DrawPrimitives(PrimitiveType::TriangleList, 0, 1);
            dev.SetVertexBuffer(nullptr);
        }

        // Triangle 2: near, tri-color (red/green/gold) -- proves interpolation + depth test
        // (this one is nearer than triangle 1 and partially overlaps it).
        {
            const VertexPositionColor verts[3] = {
                { Vector3( 0.0f,  0.6f, 0.3f), Color::Red },
                { Vector3(-0.7f, -0.6f, 0.3f), Color(0, 220, 90, 255) },
                { Vector3( 0.7f, -0.6f, 0.3f), Color(240, 200, 40, 255) },
            };
            VertexBuffer vb(dev, 3);
            vb.SetData(verts, 3);
            dev.SetVertexBuffer(&vb);
            dev.DrawPrimitives(PrimitiveType::TriangleList, 0, 1);
            dev.SetVertexBuffer(nullptr);
        }

        SaveBackBufferScreenshotEXT(dev, "/tmp/claude-0/-home-user-cna-bible/492f0769-e27b-5490-aeaf-88fd0e7e494d/scratchpad/cna_software_screenshot.png");
        std::printf("[DONE] screenshot written\n");

        Exit();
    }

public:
    ScreenshotDemo()
    {
        gdm_ = std::make_unique<GraphicsDeviceManager>(this);
        gdm_->setPreferredBackBufferWidthProperty(256);
        gdm_->setPreferredBackBufferHeightProperty(256);
    }
};

int main()
{
    ScreenshotDemo game;
    game.Run();
    return 0;
}
