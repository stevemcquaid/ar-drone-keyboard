express = require 'express'
ejs = require 'ejs'
arDrone = require("ar-drone")

control = arDrone.createUdpControl()
start = Date.now()
ref = {}
pcmd = {}

animationInProgress = 0
animationTimer = 0
animationName = ""
animationDuration = 1000

app = express()

app.configure ->
  app.use(express.bodyParser())
  app.set('dirname', __dirname)
  app.use(app.router)
  app.use(express.static(__dirname + "/public/"))
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true}))
  app.set('views',__dirname + "/views/")

app.get "/", (req,res) ->
  res.render 'index.ejs'

port = process.env.PORT || 8080
app.listen port
console.log "Listening on Port '#{port}'"

class Drone
  constructor: (speed) ->
    @speed = speed
    @accel = 0.01

    animationTimer = 0
    animationName = ""
    animationDuration = 1000

  takeoff: ->
    console.log "Takeoff ..."
    ref.emergency = false
    ref.fly = true

  land: ->
    console.log "Landing ..."
    ref.fly = false
    pcmd = {}

  stop: ->
    pcmd = {}

  commands: (names) =>
    pcmd = {}
    for name in names
      pcmd[name] = @speed
    console.log 'PCMD: ', pcmd
  
  increaseSpeed: =>
    @speed += @accel
    console.log @speed

  decreaseSpeed: =>
    @speed -= @accel
    console.log @speed

  randomTrick: =>
    if (animationTimer <= 0)
      animationTimer = 1000 #set delay before next animation can be triggered
      animations = [
        "theta20degYaw200deg", "theta20degYawM200deg", "turnaround", "turnaroundGodown", 
        "vzDance", "wave", "phiThetaMixed", "doublePhiThetaMixed"
      ];
      animationName = animations[Math.floor(Math.random() * animations.length)]
      animationDuration = 1000
      console.log animationName #what trick are we doing?

  flip: =>
    if (animationTimer <= 0)
      animationTimer = 3000 #set delay before next animation can be triggered
      animations = [
        "flipAhead", "flipBehind", "flipLeft", "flipRight"
      ];
      animationName = animations[Math.floor(Math.random() * animations.length)]
      animationDuration = 1000
      console.log animationName #what trick are we doing?

setInterval (->
  control.ref ref
  control.pcmd pcmd
  if (animationTimer > 0)
    animationTimer -= 30

  if (animationName != "" && animationTimer <= 0)
    #animation can only happen once per 1000 seconds
    control.animate(animationName, animationDuration)
    #reset vars after flip
    animationName = ""
    animationDuration = 1000

  control.flush()
), 30

drone = new Drone(0.5)

drone.speed = 1.1

console.log drone 

io = require("socket.io").listen(8081)
io.sockets.on "connection", (socket) ->
  socket.on "takeoff", drone.takeoff
  socket.on "land", drone.land
  socket.on "stop", drone.stop
  socket.on "command", drone.commands
  socket.on "increaseSpeed", drone.increaseSpeed
  socket.on "decreaseSpeed", drone.decreaseSpeed
  socket.on "randomTrick", drone.randomTrick
  socket.on "flip", drone.flip