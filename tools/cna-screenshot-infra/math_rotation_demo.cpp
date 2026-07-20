// SPDX-License-Identifier: MS-PL
// Book worked example (Vol.I Ch.7, Math and Core Types): draws a single triangle rotated
// around Z by a real Matrix::CreateRotationZ, composed with a real Matrix::CreateTranslation
// and a real Matrix::CreatePerspectiveFieldOfView/Matrix::CreateLookAt view/projection chain --
// exactly the World*View*Projection pattern every later graphics chapter assumes. Rendered
// through the SOFTWARE backend and screenshotted for the book, headlessly, no DISPLAY/GPU.

#include "Microsoft/Xna/Framework/Game.hpp"
#include "Microsoft/Xna/Framework/GraphicsDeviceManager.hpp"
#include "Microsoft/Xna/Framework/Color.hpp"
#include "Microsoft/Xna/Framework/MathHelper.hpp"
#include "Microsoft/Xna/Framework/Matrix.hpp"
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

class MathRotationDemo : public Game
{
    std::unique_ptr<GraphicsDeviceManager> gdm_;

protected:
    void Draw(const GameTime&) override
    {
        auto& dev = getGraphicsDeviceProperty();
        dev.setRasterizerStateProperty(RasterizerState::CullNone);
        dev.Clear(Color(20, 20, 30, 255), 1.0f);

        // A real 30-degree rotation around Z, composed with a translation --
        // Matrix::CreateRotationZ and Matrix::CreateTranslation, multiplied in the
        // order that matters: rotate first, then move to world position.
        const float angle = MathHelper::ToRadians(30.0f);
        const Matrix world = Matrix::CreateRotationZ(angle) *
                              Matrix::CreateTranslation(Vector3(0.0f, 0.0f, 0.0f));

        // A real view matrix from a camera position/target/up triple, and a real
        // perspective projection from a field of view + aspect ratio + near/far planes.
        const Matrix view = Matrix::CreateLookAt(
            Vector3(0.0f, 0.0f, 3.0f), Vector3::Zero, Vector3::Up);
        const Matrix projection = Matrix::CreatePerspectiveFieldOfView(
            MathHelper::PiOver4, 1.0f, 0.1f, 100.0f);

        BasicEffect fx(dev);
        fx.VertexColorEnabled = true;
        fx.World = world;
        fx.View = view;
        fx.Projection = projection;
        fx.Apply();

        const VertexPositionColor verts[3] = {
            { Vector3( 0.0f,  0.8f, 0.0f), Color::Red },
            { Vector3(-0.8f, -0.6f, 0.0f), Color(0, 220, 90, 255) },
            { Vector3( 0.8f, -0.6f, 0.0f), Color(60, 140, 255, 255) },
        };
        VertexBuffer vb(dev, 3);
        vb.SetData(verts, 3);
        dev.SetVertexBuffer(&vb);
        dev.DrawPrimitives(PrimitiveType::TriangleList, 0, 1);
        dev.SetVertexBuffer(nullptr);

        SaveBackBufferScreenshotEXT(dev, "/tmp/claude-0/-home-user-cna-bible/492f0769-e27b-5490-aeaf-88fd0e7e494d/scratchpad/cna_math_rotation_screenshot.png");
        std::printf("[DONE] screenshot written\n");

        Exit();
    }

public:
    MathRotationDemo()
    {
        gdm_ = std::make_unique<GraphicsDeviceManager>(this);
        gdm_->setPreferredBackBufferWidthProperty(256);
        gdm_->setPreferredBackBufferHeightProperty(256);
    }
};

int main()
{
    MathRotationDemo game;
    game.Run();
    return 0;
}
