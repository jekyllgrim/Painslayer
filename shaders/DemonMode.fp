void main()
{
	vec4 color = vec4(texture(InputTexture, TexCoord));
	if(color.r > 0.9 && color.g < 0.1 && color.b > 0.9)
	{
		FragColor = vec4(1.0,0.0,0.0,color.a);
	}
	else
	{
		float gray = dot(color.rgb, vec3(0.3, 0.56, 0.14));
		FragColor = mix(color, vec4(1.0 - gray,1.0 - gray,1.0 - gray,color.a), 1.0);
	}
	
}