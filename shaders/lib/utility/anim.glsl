float GetAnimationFactor() {
	#ifdef ANIM_WORLD_TIME
		float timeF = (worldTime / 24.0e3);
		return mod(timeF * 1200.0, 3600.0);
	#else
		return frameTimeCounter;
	#endif
}
