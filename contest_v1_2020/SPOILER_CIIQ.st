'From Pharo7.0.4 of 13 August 2019 [Build information: Pharo-7.0.4+build.168.sha.ccd1f6489120f58ddeacb2cac77cd3a0f0dcfbe6 (64 Bit)] on 7 March 2020 at 8:29:09.295308 am'!
RobotMind subclass: #CIIQ
	instanceVariableNames: 'map curdirs curpre curvals adj rcount moveq mqi mxnode issetup'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'JRMPC-Phase1-Minds'!

!CIIQ methodsFor: 'initialization' stamp: 'KeenanGugeler 3/5/2020 20:45'!
setDirection: vec

	direction := RobotDirection allDirections detect: [ :d | d movement = vec ].! !


!CIIQ methodsFor: 'running' stamp: 'KeenanGugeler 3/5/2020 20:45'!
setupOn: robot

	issetup := false.

   moveq := OrderedCollection new.
   mqi := 1.

	rcount := 1.! !

!CIIQ methodsFor: 'running' stamp: 'KeenanGugeler 3/5/2020 20:45'!
recoverOn: robot
	
	Transcript show: 'Recovering... '.
	Transcript show: rcount.
	Transcript show: robot location.
	rcount := rcount + 1.
	
	Transcript cr.! !

!CIIQ methodsFor: 'running' stamp: 'KeenanGugeler 3/6/2020 21:51'!
determineDirectionForRobot: robot
  | dists myvals mydirs best bestpt cur mypre mstack newq |

  mxnode := 3000.

  "in theory, we shouldnt TLE much"
  "if there is stuff on the queue, use it because its our last best computation"
  (mqi <= moveq size) ifTrue: [
    self popQueue.

	 " Yikers, we havent setup yet. We should do that..."

	 issetup ifFalse: [ self doSetup. ].

    "we feel safe, so BFS far"
    mxnode := 10000.
  ].

  map := robot map.

  dists := self getDists: robot location.

  mydirs := curdirs.
  myvals := curvals.
  mypre := curpre.

  best := -10000000.

  dists keysAndValuesDo: [ :k :v |
	 (v = 0) ifFalse: [
    	cur := (myvals at: k) / v.
    	(best < cur) ifTrue: [
      		best := cur.
      		bestpt := k.
    	].
	 ].
  ].

  mstack := OrderedCollection new.
  [bestpt = robot location] whileFalse: [
    mstack add: (mydirs at: bestpt).
    bestpt := mypre at: bestpt.
  ].

  newq := OrderedCollection new.

  mstack size to: 1 by: -1 do: [ :i |
	 newq add: (mstack at: i).
  ].

  mqi := 1.

  moveq := newq.
  self popQueue. ! !


!CIIQ methodsFor: 'as yet unclassified' stamp: 'KeenanGugeler 3/5/2020 21:04'!
getDists: source
  | q qi dists steps |
  dists := Dictionary new.
  curdirs := Dictionary new.
  curpre := Dictionary new.
  curvals := Dictionary new.
  steps := map stepsRemaining max: 1.

  dists at: source put: 0.
  curvals at: source put: 0.
  q := OrderedCollection new.
  q add: source.
  qi := 1.

  [ qi <= (mxnode min: q size) ] whileTrue: [
    | ndst pt curenergy |
    pt := q at: qi.
    curenergy := curvals at: pt.
    ndst := (dists at: pt) + 1.
    self doAdjacent: pt func: [ :dir :nxt |
      | newenergy |
      newenergy := curenergy + (map cells at: nxt) energy.
      (dists includesKey: nxt) ifFalse: [
		  (ndst > steps) ifFalse: [
        	q add: nxt.
    	  ].
    
		  dists at: nxt put: ndst.
        curpre at: nxt put: pt.
        curdirs at: nxt put: dir.
        curvals at: nxt put: newenergy.
      ]; ifTrue: [
        (((dists at: nxt) = ndst) and: [newenergy > (curvals at: nxt)]) ifTrue: [
          curvals at: nxt put: newenergy.
          curpre at: nxt put: pt.
          curdirs at: nxt put: dir.
        ].
      ].
    ].
    qi := qi + 1.
  ].
  ^dists.! !

!CIIQ methodsFor: 'as yet unclassified' stamp: 'KeenanGugeler 3/5/2020 21:09'!
doSetup

	adj := Dictionary new.
	
	map cellsDo: [ :cell |
		
		| cpt |
		
		cpt := cell location.
		
		adj at: cpt put: Dictionary new.
		
		self doAdjacent: cell location func: [ :d :pt | 
			(adj at: cpt) at: d put: pt.
		].
	].

   issetup := true.

 	Transcript show: 'Setup the grid on move '.
	Transcript show: map stepsRemaining.
	Transcript cr.
! !

!CIIQ methodsFor: 'as yet unclassified' stamp: 'KeenanGugeler 3/5/2020 20:45'!
popQueue
	self setDirection: (moveq at: mqi).
	mqi := mqi + 1.! !

!CIIQ methodsFor: 'as yet unclassified' stamp: 'KeenanGugeler 3/5/2020 21:07'!
doAdjacent: point func: f

	(issetup) ifFalse: [
		RobotDirection allDirections do: [ :d |
			
			| newpt newcell dvec |
			
			dvec := d movement.
			
			newpt := map normalizePoint: (point + dvec).
			
			newcell := map cells at: newpt.
		
			(newcell energy = 0) ifFalse: [ 
				f value: dvec value: newcell location.
			]; ifTrue: [
				(newcell isKindOf: DeathCell) ifFalse: [ 
					(newcell isKindOf: WarpCell) ifTrue: [ 
						newpt := newcell target.
					].
					(newcell isKindOf: JumpCell) ifTrue: [ 
						newpt := map normalizePoint: (newpt + (dvec * newcell distance)).
					].
			
					f value: dvec value: newpt.
				].
			].
		].
	]; ifTrue: [ 
	
		" If we are setup, use precached adjacency list"
	
		(adj at: point) keysAndValuesDo: [ :k :nxt | f value: k value: nxt ]
	
	]! !
