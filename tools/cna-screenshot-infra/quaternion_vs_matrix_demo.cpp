// SPDX-License-Identifier: MS-PL
// Book worked example (Vol.I Ch.7, Math and Core Types): confirms, both numerically and
// visually, that Matrix::CreateRotationZ(angle) and the equivalent
// Matrix::CreateFromQuaternion(Quaternion::CreateFromAxisAngle(Vector3::Backward, angle))
// produce the same rotation. Renders through the SOFTWARE backend and screenshots the
// Quaternion-derived version headlessly, no DISPLAY/GPU.

#include "Microsoft/Xna/Framework/Game.hpp"
#include "Microsoft/Xna/Framework/GraphicsDeviceManager.hpp"
#include "Microsoft/Xna/Framework/Color.hpp"
#include "Microsoft/Xna/Framework/MathHelper.hpp"
#include "Microsoft/Xna/Framework/Matrix.hpp"
#include "Microsoft/Xna/Framework/Quaternion.hpp"
#include "Microsoft/Xna/Framework/Vector3.hpp"
#include "Microsoft/Xna/Framework/Graphics/BasicEffect.hpp"
#include "Microsoft/Xna/Framework/Graphics/GraphicsDevice.hpp"
#include "Microsoft/Xna/Framework/Graphics/PrimitiveType.hpp"
#include "Microsoft/Xna/Framework/Graphics/RasterizerState.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexBuffer.hpp"
#include "Microsoft/Xna/Framework/Graphics/VertexPositionColor.hpp"

#include "../examples/common/ScreenshotEXT.hpp"

#include <cmath>
#include <cstdio>
#include <memory>

using namespace Microsoft::Xna::Framework;
using namespace Microsoft::Xna::Framework::Graphics;

class QuaternionVsMatrixDemo : public Game
{
    std::unique_ptr<GraphicsDeviceManager> gdm_;

protected:
    void Draw(const GameTime&) override
    {
        auto& dev = getGraphicsDeviceProperty();
        dev.setRasterizerStateProperty(RasterizerState::CullNone);

        const float angle = MathHelper::ToRadians(30.0f);

        // Path 1: the same Matrix::CreateRotationZ this chapter's earlier worked
        // example used.
        const Matrix matrixWorld = Matrix::CreateRotationZ(angle);

        // Path 2: the equivalent rotation built from a Quaternion instead.
        // Vector3::Backward is (0,0,1) per this chapter's own Vector3 coverage --
        // the axis that makes CreateFromAxisAngle's right-hand rotation match
        // CreateRotationZ's convention exactly.
        const Quaternion q = Quaternion::CreateFromAxisAngle(Vector3::Backward, angle);
        const Matrix quaternionWorld = Matrix::CreateFromQuaternion(q);

        // Numeric comparison: every one of the 16 components, side by side.
        float maxAbsDiff = 0.0f;
        const float* m = reinterpret_cast<const float*>(&matrixWorld);
        const float* qm = reinterpret_cast<const float*>(&quaternionWorld);
        for (int i = 0; i < 16; ++i)
        {
            const float diff = std::fabs(m[i] - qm[i]);
            if (diff > maxAbsDiff) maxAbsDiff = diff;
        }
        std::printf("[CHECK] max abs component difference (Matrix vs Quaternion path): %g\n",
                    maxAbsDiff);

        // Also confirm by transforming the same world-space point through both and
        // comparing the resulting positions directly.
        const Vector3 testPoint(0.7f, 0.3f, 0.0f);
        const Vector3 viaMatrix = Vector3::Transform(testPoint, matrixWorld);
        const Vector3 viaQuaternion = Vector3::Transform(testPoint, quaternionWorld);
        std::printf("[CHECK] transformed point via Matrix:     (%.6f, %.6f, %.6f)\n",
                    viaMatrix.X, viaMatrix.Y, viaMatrix.Z);
        std::printf("[CHECK] transformed point via Quaternion: (%.6f, %.6f, %.6f)\n",
                    viaQuaternion.X, viaQuaternion.Y, viaQuaternion.Z);

        // Render the Quaternion-derived version through the identical scene this
        // chapter's earlier Matrix-only worked example used, to visually confirm it
        // produces the same rotated triangle.
        dev.Clear(Color(20, 20, 30, 255), 1.0f);

        const Matrix view = Matrix::CreateLookAt(
            Vector3(0.0f, 0.0f, 3.0f), Vector3::Zero, Vector3::Up);
        const Matrix projection = Matrix::CreatePerspectiveFieldOfView(
            MathHelper::PiOver4, 1.0f, 0.1f, 100.0f);

        BasicEffect fx(dev);
        fx.VertexColorEnabled = true;
        fx.World = quaternionWorld;
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

        SaveBackBufferScreenshotEXT(dev, "/tmp/claude-0/-home-user-cna-bible/492f0769-e27b-5490-aeaf-88fd0e7e494d/scratchpad/cna_quaternion_vs_matrix_screenshot.png");
        std::printf("[DONE] screenshot written\n");

        Exit();
    }

public:
    QuaternionVsMatrixDemo()
    {
        gdm_ = std::make_unique<GraphicsDeviceManager>(this);
        gdm_->setPreferredBackBufferWidthProperty(256);
        gdm_->setPreferredBackBufferHeightProperty(256);
    }
};

int main()
{
    QuaternionVsMatrixDemo game;
    game.Run();
    return 0;
}
