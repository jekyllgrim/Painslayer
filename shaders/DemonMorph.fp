//Original shader code by Devon O. Wolfgang, modified for GZDoom by Cherno and Agent_Ash
//Original credit below
/**
 *    Copyright (c) 2017 Devon O. Wolfgang
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to deal
 *    in the Software without restriction, including without limitation the rights
 *    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *    copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *    THE SOFTWARE.
 */

void main()
{
	ivec2 res = textureSize(InputTexture, 0);
	vec2 center = vec2(centerX, centerY);
	float time = rippleTimer * waveSpeed;
	float amt = amount / 1000;

	vec2 uv = center.xy - TexCoord;
	uv.x *= res.x / res.y;

	float dist = sqrt(dot(uv,uv));
	amt *= 0.5 - sqrt(dot(uv,uv));
	float ang = dist * waveAmount - time;
	
	//where the magic happens... Experiment with different calculations,
	//exchange sin with cos, and so on...
	uv = TexCoord + normalize(uv) * sin(ang) * amt;
	vec4 color = vec4(texture(InputTexture, uv));
	
	//vec4 color = vec4(texture(InputTexture, TexCoord));//normal texture reading
	
	vec4 colorFinal = color;
	if(color.r > 0.8 && color.g < 0.1 && color.b > 0.8)
	{
		colorFinal = vec4(1.0,0.0,0.0,color.a);
	}
	else
	{
		float gray = dot(color.rgb, vec3(0.3, 0.56, 0.14));
		//colorFinal = mix(color, vec4(1.0 - gray,1.0 - gray,1.0 - gray,color.a), 1.0);
		colorFinal = mix(color, vec4(gray,gray,gray,color.a), 1.0);
		//colorFinal = clamp(mix(color, color * color * (3 - 2 * color), 10), 0.0f, 1.0f); //high contrast
		colorFinal *= pow(2.0f, 1.5); //exposure
	}
	FragColor = colorFinal;
}

