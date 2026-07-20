// SPDX-License-Identifier: MS-PL
// Book worked example (Vol.I Ch.9, GraphicsDevice): a real render-target round trip -- draws a
// scene into an offscreen RenderTarget2D via GraphicsDevice::SetRenderTarget, restores the back
// buffer (SetRenderTarget(nullptr)), then draws the render target's own contents back into the
// main scene as a small inset via SpriteBatch, proving the round trip is real (the inset shows
// actual rendered content, not a placeholder). Rendered through the SOFTWARE backend and
// screenshotted for the book, headlessly, no DISPLAY/GPU.

#include "Microsoft/Xna/Framework/Game.hpp"
#include "Microsoft/Xna/Framework/GraphicsDeviceManager.hpp"
#include "Microsoft/Xna/Framework/Color.hpp"
#include "Microsoft/Xna/Framework/Rectangle.hpp"
#include "Microsoft/Xna/Framework/Vector2.hpp"
#include "Microsoft/Xna/Framework/Vector3.hpp"
#include "Microsoft/Xna/Framework/Graphics/BasicEffect.hpp"
#include "Microsoft/Xna/Framework/Graphics/GraphicsDevice.hpp"
#include "Microsoft/Xna/Framework/Graphics/PrimitiveType.hpp"
#include "Microsoft/Xna/Framework/Graphics/RasterizerState.hpp"
#include "Microsoft/Xna/Framework/Graphics/RenderTarget2D.hpp"
#include "Microsoft/Xna/Framework/Graphics/SpriteBatch.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexBuffer.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexPositionColor.hpp"

#include "../examples/common/ScreenshotEXT.hpp"

#include <cstdio>
#include <memory>

using namespace Microsoft::Xna::Framework;
using namespace Microsoft::Xna::Framework::Graphics;

class RenderTargetRoundtripDemo : public Game
{
    std::unique_ptr<GraphicsDeviceManager> gdm_;

    void DrawTriangle(GraphicsDevice& dev, const VertexPositionColor verts[3])
    {
        VertexBuffer vb(dev, 3);
        vb.SetData(verts, 3);
        dev.SetVertexBuffer(&vb);
        dev.DrawPrimitives(PrimitiveType::TriangleList, 0, 1);
        dev.SetVertexBuffer(nullptr);
    }

protected:
    void Draw(const GameTime&) override
    {
        auto& dev = getGraphicsDeviceProperty();
        dev.setRasterizerStateProperty(RasterizerState::CullNone);

        BasicEffect fx(dev);
        fx.VertexColorEnabled = true;
        fx.World = Matrix::getIdentityProperty();
        fx.View = Matrix::getIdentityProperty();
        fx.Projection = Matrix::getIdentityProperty();

        // Pass 1: render a bright orange/purple scene into an offscreen 128x128
        // render target -- SetRenderTarget redirects every following draw call.
        RenderTarget2D offscreen(dev, 128, 128);
        dev.SetRenderTarget(&offscreen);
        dev.Clear(Color(60, 20, 80, 255), 1.0f);
        fx.Apply();
        const VertexPositionColor offscreenTri[3] = {
            { Vector3( 0.0f,  0.7f, 0.0f), Color(255, 140, 0, 255) },
            { Vector3(-0.7f, -0.6f, 0.0f), Color(255, 210, 0, 255) },
            { Vector3( 0.7f, -0.6f, 0.0f), Color(255, 90, 0, 255) },
        };
        DrawTriangle(dev, offscreenTri);

        // Confirm the offscreen render target really was drawn into correctly,
        // while it is still bound, by reading a pixel directly from its center
        // (should land inside the orange/gold triangle just drawn above).
        {
            Color centerPixel(0, 0, 0, 0);
            const Rectangle centerRegion(64, 64, 1, 1);
            dev.GetBackBufferData(&centerRegion, &centerPixel, 0, 1);
            std::printf("[CHECK] offscreen center pixel while bound: R=%d G=%d B=%d A=%d\n",
                        centerPixel.getRProperty(), centerPixel.getGProperty(),
                        centerPixel.getBProperty(), centerPixel.getAProperty());
        }

        // Restore the back buffer -- SetRenderTarget(nullptr) per this chapter's own
        // documentation of the call, and confirm via GetRenderTargets() that the
        // back buffer really is active again (an empty vector means "back buffer").
        dev.SetRenderTarget(nullptr);
        const bool backBufferActive = dev.GetRenderTargets().empty();
        std::printf("[CHECK] back buffer active after unbind: %s\n",
                    backBufferActive ? "true" : "false");

        // Pass 2: main scene -- a plain teal background triangle, drawn the same
        // raw GraphicsDevice::DrawPrimitives way as Chapter 9's first worked example.
        dev.Clear(Color(20, 45, 45, 255), 1.0f);
        fx.Apply();
        const VertexPositionColor mainTri[3] = {
            { Vector3(-0.9f,  0.9f, 0.0f), Color(0, 150, 150, 255) },
            { Vector3(-0.9f, -0.9f, 0.0f), Color(0, 100, 130, 255) },
            { Vector3( 0.9f, -0.2f, 0.0f), Color(0, 130, 160, 255) },
        };
        DrawTriangle(dev, mainTri);

        // Now draw the *offscreen render target's own contents* back into the main
        // scene as a picture-in-picture inset via SpriteBatch -- proving the round
        // trip actually captured real pixels, not a blank/placeholder texture.
        SpriteBatch batch(dev);
        batch.Begin();
        batch.Draw(offscreen, Rectangle(146, 20, 90, 90), Color::White);
        batch.End();

        SaveBackBufferScreenshotEXT(dev, "/tmp/claude-0/-home-user-cna-bible/492f0769-e27b-5490-aeaf-88fd0e7e494d/scratchpad/cna_rendertarget_roundtrip_screenshot.png");
        std::printf("[DONE] screenshot written\n");

        Exit();
    }

public:
    RenderTargetRoundtripDemo()
    {
        gdm_ = std::make_unique<GraphicsDeviceManager>(this);
        gdm_->setPreferredBackBufferWidthProperty(256);
        gdm_->setPreferredBackBufferHeightProperty(256);
    }
};

int main()
{
    RenderTargetRoundtripDemo game;
    game.Run();
    return 0;
}
