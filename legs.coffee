window.Robot = {}

#A rigid box
class Box
  constructor: (@system, @scene, length, width, height, density = 1, color = 0x666666) ->
    geometry = new THREE.CubeGeometry length, width, height
    material = new THREE.MeshLambertMaterial color: color
    @mesh = new THREE.Mesh geometry, material
    @mesh.matrixAutoUpdate = false
    @mesh.overdraw = true
    scene.add @mesh

    body = new jiglib.JBox null, length, height, width
    body.set_mass body.getVolume() * density
    system.addBody body
    @mesh.rigidBody = body

  setPosition: (x, y, z) ->
    @mesh.position = new THREE.Vector3 x, y, z
    @mesh.updateMatrix()
    @mesh.rigidBody.moveTo(new Vector3D x, y, z)
    this

  setRotation: (x, y, z) ->
    @mesh.rotation = new THREE.Vector3 x, y, z
    @mesh.updateMatrix()

    matrix3D = new Matrix3D()
    matrix3D.appendRotation x, Vector3D.X_AXIS
    matrix3D.appendRotation y, Vector3D.Y_AXIS
    matrix3D.appendRotation z, Vector3D.Z_AXIS
    @mesh.rigidBody.setOrientation matrix3D
    this

#A single axis joint
class Joint
  sidewaysSlack: 0.001
  damping: 0.0
  ###
  box0 and box1 are the two boxes being joined
  hingeAxis is the axis of rotation of the hinge
  hingePosRel0 is the offset of the hinge from the center of box0
  hingeFwdAngle and hingeBckAngle are the angles of rotation of the joint
  ###
  constructor: (box0, box1, hingeAxis, hingePosRel0, hingeHalfWidth, hingeFwdAngle, hingeBckAngle) ->
    @joint = new jiglib.HingeJoint(box0.mesh.rigidBody, box1.mesh.rigidBody, hingeAxis, hingePosRel0, hingeHalfWidth, hingeFwdAngle, hingeBckAngle, @sidewaysSlack, @damping)

  angle: ->
    body0State = @joint._body0.get_currentState()
    body1State = @joint._body1.get_currentState()
    hingePosition = body0State.position.add(body0State.orientation.transformVector(@joint._hingePosRel0))

    """
    <p>body0 position: (#{body0State.position.x.toFixed(3)}, #{body0State.position.y.toFixed(3)}, #{body0State.position.z.toFixed(3)})</p>
    <p>body1 position: (#{body1State.position.x.toFixed(3)}, #{body1State.position.y.toFixed(3)}, #{body1State.position.z.toFixed(3)})</p>
    <p>hingePosition: (#{hingePosition.x.toFixed(3)}, #{hingePosition.y.toFixed(3)}, #{hingePosition.z.toFixed(3)})</p>
    """

class Robot.Legs
  constructor: (@system, @scene) ->
    @components = {}
    @joints = {}

    @initialize()

  remove: ->
    component.remove() for compenent in @components
    joint.remove() for joint in @joints

  addComponent: (name, component) ->
    @components[name] = component
    component

  addJoint: (name, joint) ->
    @joints[name] = joint
    joint

  initialize: ->
    #left leg
    leftFoot =        @addComponent("leftFoot", new Box @system, @scene, 4, 10, 2, 1, 0x001166).setPosition -10, 2, 1
    leftCrus =        @addComponent("leftCrus", new Box @system, @scene, 2, 4, 20, 1, 0x999999).setPosition -7, 0, 11
    leftThigh =       @addComponent("leftThigh", new Box @system, @scene, 2, 4, 20, 1, 0x0066CC).setPosition -9, 0, 29
    leftHipAdapter =  @addComponent("leftHipAdapter", new Box @system, @scene, 4, 4, 4, 1, 0x001166).setPosition -6, 0, 37
    #right leg
    rightFoot =       @addComponent("rightFoot", new Box @system, @scene, 4, 10, 2, 1, 0x001166).setPosition 10, 2, 1
    rightCrus =       @addComponent("rightCrus", new Box @system, @scene, 2, 4, 20, 1, 0x999999).setPosition 7, 0, 11
    rightThigh =      @addComponent("rightThigh", new Box @system, @scene, 2, 4, 20, 1, 0x0066CC).setPosition 9, 0, 29
    rightHipAdapter = @addComponent("rightHipAdapter", new Box @system, @scene, 4, 4, 4, 1, 0x001166).setPosition 6, 0, 37
    #body
    hip =             @addComponent("hip", new Box @system, @scene, 8, 6, 8, 4, 0x999999).setPosition 0, 0, 43

    #joints
    @addJoint "leftAnkle",        new Joint(leftFoot,        leftCrus,        Vector3D.X_AXIS, new Vector3D(2, -2, 1),  2, 90, 30)
    @addJoint "rightAnkle",       new Joint(rightFoot,       rightCrus,       Vector3D.X_AXIS, new Vector3D(-2, -2, 1), 2, 90, 30)
    @addJoint "leftKnee",         new Joint(leftCrus,        leftThigh,       Vector3D.X_AXIS, new Vector3D(-1, 0, 9),  2, 120, 0)
    @addJoint "rightKnee",        new Joint(rightCrus,       rightThigh,      Vector3D.X_AXIS, new Vector3D(1, 0, 9),   2, 90, 0)
    @addJoint "leftHipFlexor",    new Joint(leftThigh,       leftHipAdapter,  Vector3D.X_AXIS, new Vector3D(1, 0, 9),   2, 0,  90)
    @addJoint "rightHipFlexor",   new Joint(rightThigh,      rightHipAdapter, Vector3D.X_AXIS, new Vector3D(-1, 0, 9),  2, 0,  90)
    @addJoint "leftHipAbductor1",  new Joint(leftHipAdapter,  hip,            Vector3D.Y_AXIS, new Vector3D(2, 2, 2),   1, 180, 0)
    @addJoint "leftHipAbductor2",  new Joint(leftHipAdapter,  hip,            Vector3D.Y_AXIS, new Vector3D(2, -2, 2),  1, 180, 0)
    @addJoint "rightHipAbductor1", new Joint(rightHipAdapter, hip,            Vector3D.Y_AXIS, new Vector3D(-2, 2, 2),  2, 180, 180)
    @addJoint "rightHipAbductor2", new Joint(rightHipAdapter, hip,            Vector3D.Y_AXIS, new Vector3D(-2, -2, 2), 2, 180, 180)

  getState: ->
    @joints.leftKnee.angle()

  applyTorques: (torques) ->

  push: (body, x, y, z) ->
    @components[body].mesh.rigidBody.addBodyForce new Vector3D(x, y, z), new Vector3D(0,0,0)