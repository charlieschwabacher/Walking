$ ->

  #get page size and mouse position
  width = window.innerWidth
  height = window.innerHeight
  physicsEnabled = true

  #setup JigLibJS2 physics simulation
  system = jiglib.PhysicsSystem.getInstance()
  system.setCollisionSystem true
  system.setSolverType "ACCUMULATED"
  system.setGravity(new Vector3D(0, 0, -9.8, 0))

  #create Three.js scene and renderer
  scene    = new THREE.Scene()
  renderer = new THREE.WebGLRenderer antialias: true
  renderer.setSize(width, height)
  renderer.setClearColorHex(0xEEEEEE)
  renderer.clear()
  document.body.appendChild(renderer.domElement)

  #setup lights and camera
  camera   = new THREE.PerspectiveCamera(75, width / height, 1, 10000)
  light    = new THREE.PointLight()
  ambient  = new THREE.AmbientLight()
  camera.position = new THREE.Vector3 0, -100, 30
  camera.lookAt new THREE.Vector3 0, 0, 28
  light.position = camera.position

  setupCamera = ->
    scene.add(camera)
    scene.add(light)
    scene.add(ambient)
  setupCamera()

  controls = new THREE.TrackballControls camera, renderer.domElement
  controls.rotateSpeed = 1.0;
  controls.zoomSpeed = 1.2;
  controls.panSpeed = 0.2;
  controls.noZoom = false;
  controls.noPan = false;
  controls.staticMoving = false;
  controls.dynamicDampingFactor = 0.3;
  controls.minDistance = 30;
  controls.maxDistance = 500;
  controls.keys = [ 65, 83, 68 ]; #[ rotateKey, zoomKey, panKey ]

  #set up menu buttons
  pushStrength = 1000000
  body = document.getElementById('pushBody').value
  document.getElementById('pushBody').onchange = (e) ->
    body = e.target.value
  document.getElementById('pushLeft').onclick = ->
    legs.push(body, -pushStrength, 0, 0)
  document.getElementById('pushRight').onclick = ->
    legs.push(body, pushStrength, 0, 0)
  document.getElementById('pushForward').onclick = ->
    legs.push(body, 0, pushStrength, 0)
  document.getElementById('pushBack').onclick = ->
    legs.push(body, 0, -pushStrength, 0)
  document.getElementById('pushUp').onclick = ->
    legs.push(body, 0, 0, pushStrength)
  document.getElementById('reset').onclick = ->
    system.removeAllBodies()
    system.removeAllConstraints()
    scene = new THREE.Scene()
    setupHorizon()
    setupCamera()
    legs.scene = scene
    legs.initialize()

  #create div to display simulation info
  display = document.createElement("div")
  display.id = "display"
  document.body.appendChild(display)

  #create horizon
  setupHorizon = ->
    system.addBody new jiglib.JPlane(null, new Vector3D(0,0,1))
    scene.add new THREE.Mesh(
      new THREE.PlaneGeometry(10000, 10000, 100, 100),
      new THREE.MeshBasicMaterial(color: 0xCCCCCC, wireframe: true)
    )
  setupHorizon();

  #create robot legs
  legs = new Robot.Legs(system, scene)

  #draw loop
  t0 = new Date().getTime()
  frame = 0
  elapsedMs = 0
  elapsedFrames = 0
  fps = 0
  animate = ->
    #track FPS
    t1 = new Date().getTime()
    elapsedMs += t1 - t0
    t0 = t1
    frame += 1
    elapsedFrames += 1

    if elapsedMs >= 1000
      elapsedMs -= 1000
      fps = elapsedFrames
      elapsedFrames = 0

    if frame % 10 == 0
      document.getElementById('display').innerHTML = "<h1>#{fps} fps</h1>" + legs.getState()

    requestAnimationFrame(animate) unless document.webkitHidden

    updateDynamicsWorld()
    render()

  #update THREE.js scene from physics simulation
  updateDynamicsWorld = ->
    system.integrate( 0.02 )

    for i in [0...scene.children.length]
      mesh = scene.children[i]
      if mesh.rigidBody?
        if physicsEnabled
          pos = mesh.rigidBody.get_currentState().position
          dir = mesh.rigidBody.get_currentState().orientation.get_rawData()

          matrix = new THREE.Matrix4()
          matrix.setTranslation pos.x, pos.y, pos.z
          rotate = new THREE.Matrix4(
            dir[0], dir[1], dir[2], dir[3],
            dir[4], dir[5], dir[6], dir[7],
            dir[8], dir[9], dir[10], dir[11],
            dir[12], dir[13], dir[14], dir[15]
          )
          matrix.multiplySelf rotate
          mesh.matrix = matrix
        mesh.updateMatrixWorld(true)
    null

  #render Three.js scene to canvas
  render = ->
    controls.update()
    renderer.clear()
    renderer.render(scene, camera)

  #start animation
  animate()
