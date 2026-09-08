import CoreGraphics
import Testing
@testable import SelfieJourney

struct FaceGuidanceTests {
    private let goodLight = FaceLightEstimate(scene: 0.5, face: 0.45)

    private func face(_ pose: PortraitPose = .classic, x: CGFloat = 0.5, y: CGFloat? = nil,
                      height: CGFloat? = nil, eyes: CGPoint? = nil,
                      yaw: Double? = 0, roll: Double? = 0, pitch: Double? = 0) -> FaceGeometry {
        let height = height ?? pose.faceHeight
        return FaceGeometry(bounds: CGRect(x: x - pose.faceWidth / 2, y: (y ?? pose.centerY) - height / 2,
                                           width: pose.faceWidth, height: height),
                            eyes: eyes, yaw: yaw, roll: roll, pitch: pitch)
    }

    @Test(arguments: PortraitPose.allCases)
    func everyPoseAcceptsItsOwnTarget(pose: PortraitPose) {
        let report = FaceGuidancePolicy.evaluate(faces: [face(pose)], light: goodLight, pose: pose)
        #expect(report.isAligned)
        #expect(report.face == .good)
        #expect(report.position == .good)
        #expect(report.light == .good)
    }

    @Test(arguments: PortraitPose.allCases)
    func framingBracketsLeaveRoomAroundTheFaceAndEyeLine(pose: PortraitPose) {
        let guide = pose.framingBounds
        let target = CGRect(x: 0.5 - pose.faceWidth / 2, y: pose.centerY - pose.faceHeight / 2,
                            width: pose.faceWidth, height: pose.faceHeight)
        #expect(guide.minX >= 0 && guide.maxX <= 1)
        #expect(guide.minY >= 0 && guide.maxY <= 1)
        #expect(guide.contains(target))
        #expect(guide.width > target.width * 1.25)
        #expect(guide.height > target.height * 1.15)
        #expect(abs(guide.midX - 0.5) < 0.00001)
        #expect(pose.eyeLineY > guide.minY && pose.eyeLineY < guide.maxY)
    }

    @Test(arguments: PortraitPose.allCases)
    func differentFaceWidthsDoNotRequireMatchingAnOutline(pose: PortraitPose) {
        for width in [pose.faceWidth * 0.75, pose.faceWidth * 1.25] {
            var geometry = face(pose, eyes: CGPoint(x: 0.5, y: pose.eyeLineY))
            geometry.bounds = CGRect(x: 0.5 - width / 2, y: geometry.bounds.minY,
                                     width: width, height: geometry.bounds.height)
            #expect(FaceGuidancePolicy.evaluate(faces: [geometry], light: goodLight, pose: pose).isAligned)
        }
    }

    @Test(arguments: PortraitPose.allCases)
    func naturalFramingVariationIsAcceptedWithoutChasingAnExactFit(pose: PortraitPose) {
        for factor in [0.88, 1.12] {
            let geometry = face(pose, x: 0.54, height: pose.faceHeight * factor,
                                eyes: CGPoint(x: 0.54, y: pose.eyeLineY + 0.04))
            #expect(FaceGuidancePolicy.evaluate(faces: [geometry], light: goodLight, pose: pose).isAligned)
        }
    }

    @Test func noFaceAndMultipleFacesHaveUsefulDistinctAdvice() {
        #expect(FaceGuidancePolicy.evaluate(faces: [], light: goodLight, pose: .classic).cue == .noFace)
        let faces = [face(x: 0.4), face(x: 0.7)]
        #expect(FaceGuidancePolicy.evaluate(faces: faces, light: goodLight, pose: .classic).cue == .multipleFaces)
        #expect(FaceGuidancePolicy.evaluate(faces: faces, light: FaceLightEstimate(scene: 0.1, face: nil), pose: .classic).cue == .multipleFaces)
    }

    @Test func darknessCanExplainWhyNoFaceWasFound() {
        let report = FaceGuidancePolicy.evaluate(faces: [], light: FaceLightEstimate(scene: 0.1, face: nil), pose: .classic)
        #expect(report.cue == .lowLight)
        #expect(report.light == .adjust)
        #expect(report.face == .adjust)
    }

    @Test func lightingAdviceTakesPriorityOverPoseRefinements() {
        let dark = FaceLightEstimate(scene: 0.12, face: 0.1)
        let report = FaceGuidancePolicy.evaluate(faces: [face(x: 0.2, yaw: 0.4)], light: dark, pose: .classic)
        #expect(report.cue == .lowLight)
        #expect(report.face == .adjust)
        #expect(report.position == .adjust)
        #expect(report.light == .adjust)
    }

    @Test func shadowAdviceRequiresBothLowFaceBrightnessAndBackgroundContrast() {
        let backlit = FaceLightEstimate(scene: 0.5, face: 0.2)
        #expect(FaceGuidancePolicy.evaluate(faces: [face()], light: backlit, pose: .classic).cue == .backlit)
        let lowContrast = FaceLightEstimate(scene: 0.28, face: 0.2)
        #expect(FaceGuidancePolicy.evaluate(faces: [face()], light: lowContrast, pose: .classic).cue == .aligned)
        let brightFace = FaceLightEstimate(scene: 0.7, face: 0.4)
        #expect(FaceGuidancePolicy.evaluate(faces: [face()], light: brightFace, pose: .classic).cue == .aligned)
    }

    @Test func unavailableLightMeasurementsStayUnknown() {
        let report = FaceGuidancePolicy.evaluate(faces: [face()], light: nil, pose: .classic)
        #expect(report.cue == .aligned)
        #expect(report.light == .unknown)
        #expect(FaceGuidance.manual.light == .unknown)
        #expect(!FaceGuidance.manual.isAligned)
    }

    @Test(arguments: PortraitPose.allCases)
    func distanceAdviceUsesTheSelectedPose(pose: PortraitPose) {
        #expect(FaceGuidancePolicy.evaluate(faces: [face(pose, height: pose.faceHeight * 0.7)], light: goodLight, pose: pose).cue == .moveCloser)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(pose, height: pose.faceHeight * 1.3)], light: goodLight, pose: pose).cue == .moveBack)
    }

    @Test func directionAdviceUsesMirroredPreviewCoordinates() {
        #expect(FaceGuidancePolicy.evaluate(faces: [face(x: 0.3)], light: goodLight, pose: .classic).cue == .moveRight)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(x: 0.7)], light: goodLight, pose: .classic).cue == .moveLeft)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(y: 0.25)], light: goodLight, pose: .classic).cue == .moveDown)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(y: 0.65)], light: goodLight, pose: .classic).cue == .moveUp)
    }

    @Test func eyeLineTakesPriorityOverTheFaceRectangleCenter() {
        let matchingEyes = CGPoint(x: 0.5, y: PortraitPose.classic.eyeLineY)
        let report = FaceGuidancePolicy.evaluate(faces: [face(y: 0.56, eyes: matchingEyes)], light: goodLight, pose: .classic)
        #expect(report.isAligned)
        let lowEyes = CGPoint(x: 0.5, y: matchingEyes.y + 0.08)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(eyes: lowEyes)], light: goodLight, pose: .classic).cue == .moveUp)
    }

    @Test func headAngleAdviceFollowsDocumentedVisionRadians() {
        #expect(FaceGuidancePolicy.evaluate(faces: [face(yaw: 0.4)], light: goodLight, pose: .classic).cue == .faceForward)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(yaw: -0.4)], light: goodLight, pose: .classic).cue == .faceForward)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(roll: 0.2)], light: goodLight, pose: .classic).cue == .levelHead)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(roll: -0.2)], light: goodLight, pose: .classic).cue == .levelHead)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(pitch: 0.3)], light: goodLight, pose: .classic).cue == .liftChin)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(pitch: -0.3)], light: goodLight, pose: .classic).cue == .lowerChin)
    }

    @Test func geometryCorrectionsComeBeforeHeadAngleCorrections() {
        #expect(FaceGuidancePolicy.evaluate(faces: [face(x: 0.3, height: 0.3, yaw: 0.4)], light: goodLight, pose: .classic).cue == .moveCloser)
        #expect(FaceGuidancePolicy.evaluate(faces: [face(x: 0.3, yaw: 0.4)], light: goodLight, pose: .classic).cue == .moveRight)
    }

    @Test func sustainedAdviceChangesButOneNoisyFrameDoesNot() {
        var stabilizer = FaceGuidanceStabilizer()
        let aligned = FaceGuidance(cue: .aligned, face: .good, position: .good, light: .good)
        #expect(stabilizer.update(aligned).cue == .starting)
        #expect(stabilizer.update(aligned).cue == .starting)
        #expect(stabilizer.update(aligned).cue == .aligned)
        #expect(stabilizer.update(FaceGuidance(cue: .moveLeft)).cue == .aligned)
        #expect(stabilizer.update(aligned).cue == .aligned)
        #expect(stabilizer.update(FaceGuidance(cue: .moveLeft)).cue == .aligned)
        #expect(stabilizer.update(FaceGuidance(cue: .moveLeft)).cue == .aligned)
        #expect(stabilizer.update(FaceGuidance(cue: .moveLeft)).cue == .moveLeft)
    }

    @Test func resettingForPoseOrientationOrSessionRemovesOldAdviceAndCandidates() {
        var stabilizer = FaceGuidanceStabilizer()
        for _ in 0..<3 { _ = stabilizer.update(FaceGuidance(cue: .aligned)) }
        for _ in 0..<2 { _ = stabilizer.update(FaceGuidance(cue: .moveBack)) }
        stabilizer.reset()
        #expect(stabilizer.current == .starting)
        #expect(stabilizer.update(FaceGuidance(cue: .moveBack)).cue == .starting)
    }

    @Test func portraitCoordinatesFlipOnlyTheVisionYAxis() {
        let converted = FacePreviewGeometry.rect(CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5), imageSize: CGSize(width: 900, height: 1200))
        #expect(abs(converted.minX - 0.2) < 0.00001)
        #expect(abs(converted.minY - 0.2) < 0.00001)
        #expect(abs(converted.width - 0.4) < 0.00001)
        #expect(abs(converted.height - 0.5) < 0.00001)
        let point = FacePreviewGeometry.point(CGPoint(x: 0.25, y: 0.8), imageSize: CGSize(width: 900, height: 1200))
        #expect(abs(point.x - 0.25) < 0.00001) // Buffer is already mirrored; do not flip it twice.
        #expect(abs(point.y - 0.2) < 0.00001)
    }

    @Test func landscapeAspectFillCropsHorizontallyAroundTheCenter() {
        let converted = FacePreviewGeometry.rect(CGRect(x: 0.4, y: 0.35, width: 0.2, height: 0.3), imageSize: CGSize(width: 1600, height: 1200))
        #expect(abs(converted.midX - 0.5) < 0.00001)
        #expect(abs(converted.midY - 0.5) < 0.00001)
        #expect(abs(converted.width - 0.2 * 16 / 9) < 0.00001)
        #expect(abs(converted.height - 0.3) < 0.00001)
        let visible = FacePreviewGeometry.visibleImageRect(imageSize: CGSize(width: 1600, height: 1200))
        #expect(abs(visible.width - 9.0 / 16) < 0.00001)
        #expect(abs(visible.midX - 0.5) < 0.00001)
        #expect(abs(visible.height - 1) < 0.00001)
    }

    @Test func narrowVideoAspectFillCropsVerticallyAroundTheCenter() {
        let converted = FacePreviewGeometry.rect(CGRect(x: 0.4, y: 0.35, width: 0.2, height: 0.3), imageSize: CGSize(width: 900, height: 1600))
        #expect(abs(converted.midX - 0.5) < 0.00001)
        #expect(abs(converted.midY - 0.5) < 0.00001)
        #expect(abs(converted.width - 0.2) < 0.00001)
        #expect(abs(converted.height - 0.4) < 0.00001)
    }
}
