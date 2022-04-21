local Flipper = {
	SingleMotor = require(script.SingleMotor),
	GroupMotor = require(script.GroupMotor),

	Instant = require(script.Instant),
	Linear = require(script.Linear),
	Spring = require(script.FlipperSpring),
	
	isMotor = require(script.isMotor),
}

return Flipper