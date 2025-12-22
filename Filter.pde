class Filter{
    // Owning layer, set when the filter is attached/applied.
    Layer layer;
    void apply(Layer l) {}
    
    int clamp255(int v) {
        return v < 0 ? 0 : (v > 255 ? 255 : v);
    }
    int clampInt(int v, int lo, int hi) {
        return v < lo ? lo : (v > hi ? hi : v);
    }
}
class GaussianBlurFilter extends Filter{
    int radius;
    int sigma;
    float ker[];
    boolean change;
    GaussianBlurFilter(int radius, int sigma) {
        this.radius = radius;
        this.sigma = sigma;
        this.ker =  getkernel();
    }
    
    
    void change(int radius, int sigma) {
        this.radius = radius;
        this.sigma = sigma;
        this.ker =  getkernel();
        this.change = true;
    }
    void apply(Layer l) {
        if (change) {
            this.ker = getkernel();
        }
        l.processedImg = blurHorizontal(l.processedImg,ker,radius);
        l.processedImg = blurVertical(l.processedImg,ker,radius);
    }
    
    float[] getkernel() {
        int size = 2 * radius + 1;
        float[] kernel = new float[size];
        float sum = 0;
        for (int i = -radius; i <= radius; i++) {
            float v = exp( -(i * i) / (2 * sigma * sigma));
            kernel[i + radius] = v;
            sum += v;
        }
        for (int i = 0; i < size; i++) {
            kernel[i] /= sum;
        }
        change = false;
        return kernel;
    }
    PImage blurHorizontal(PImage src, float[] kernel, int radius) {
        PImage dst = createImage(src.width, src.height, RGB);
        src.loadPixels();
        dst.loadPixels();
        
        for (int y = 0; y < src.height; y++) {
            for (int x = 0; x < src.width; x++) {
                float r = 0, g = 0, b = 0;
                float a;
                int outA = 0, outR = 0, outG = 0, outB = 0;
                float sumR = 0, sumG = 0, sumB = 0, sumA = 0;
                for (int k = -radius; k <= radius; k++) {
                    int xx = constrain(x + k, 0, src.width - 1);
                    color c = src.pixels[y * src.width + xx];
                    float w = kernel[k + radius];
                    
                    a = (c >> 24) & 0xFF;
                    r = (c >> 16) & 0xFF;
                    g = (c >> 8) & 0xFF;
                    b = c & 0xFF;
                    
                    float af = a / 255.0f;
                    float pr = r * af;
                    float pg = g * af;
                    float pb = b * af;
                    
                    sumR += pr * w;
                    sumG += pg * w;
                    sumB += pb * w;
                    sumA += a  * w;   
                    
                    outA = clamp255((int)(sumA + 0.5f));
                    
                    if (outA > 0) {
                        float invA = 255.0f / outA;
                        outR = clamp255((int)(sumR * invA + 0.5f));
                        outG = clamp255((int)(sumG * invA + 0.5f));
                        outB = clamp255((int)(sumB * invA + 0.5f));
                    } else {
                        outR = outG = outB = 0;
                    }
                }
                
                dst.pixels[y * src.width + x] = outA<<24 | outR<<16 | outG<<8 | outB;
            }
        }
        dst.updatePixels();
        return dst;
    }
    PImage blurVertical(PImage src, float[] kernel, int radius) {
        PImage dst = createImage(src.width, src.height, RGB);
        src.loadPixels();
        dst.loadPixels();
        
        for (int y = 0; y < src.height; y++) {
            for (int x = 0; x < src.width; x++) {
                float r = 0, g = 0, b = 0;
                float a;
                int outA = 0, outR = 0, outG = 0, outB = 0;
                float sumR = 0, sumG = 0, sumB = 0, sumA = 0;
                for (int k = -radius; k <= radius; k++) {
                    int yy = constrain(y + k, 0, src.height - 1);
                    color c = src.pixels[yy * src.width + x];
                    float w = kernel[k + radius];
                    
                    a = (c >> 24) & 0xFF;
                    r = (c >> 16) & 0xFF;
                    g = (c >> 8) & 0xFF;
                    b = c & 0xFF;
                    
                    float af = a / 255.0f;
                    float pr = r * af;
                    float pg = g * af;
                    float pb = b * af;
                    
                    sumR += pr * w;
                    sumG += pg * w;
                    sumB += pb * w;
                    sumA += a  * w;   
                    
                    outA = clamp255((int)(sumA + 0.5f));
                    
                    if (outA > 0) {
                        float invA = 255.0f / outA;
                        outR = clamp255((int)(sumR * invA + 0.5f));
                        outG = clamp255((int)(sumG * invA + 0.5f));
                        outB = clamp255((int)(sumB * invA + 0.5f));
                    } else {
                        outR = outG = outB = 0;
                    }
                }
                
                dst.pixels[y * src.width + x] = outA<<24 | outR<<16 | outG<<8 | outB;
            }
        }
        dst.updatePixels();
        return dst;
    }
}
class ContrastFilter extends Filter{
    float value;
    ContrastFilter(float value) {
        this.value = value;
    }
    void apply(Layer l) {
        l.processedImg.loadPixels();
        for (int i = 0; i < l.processedImg.pixels.length; i++) {
            int c = l.processedImg.pixels[i];
            
            int r = (c >> 16) & 0xFF;
            int g = (c >> 8) & 0xFF;
            int b = c & 0xFF;
            int a = (c >> 24) & 0xFF; // 保留 Alpha 通道
            
            r = (int)((r - 128) * value + 128);
            g = (int)((g - 128) * value + 128);
            b = (int)((b - 128) * value + 128);
            
            r = clamp255(r);
            g = clamp255(g);
            b = clamp255(b);
            
            l.processedImg.pixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
        }
        return;
    }
}
class SharpenFilter extends Filter{
    float value;
    SharpenFilter(float value) {
        this.value = value;
    }
    void apply(Layer l) {
        l.processedImg = sharpen(l.processedImg, ker, value);
    }
    float[] ker = {
        0, -1, 0,
        - 1, 5, -1,
        0, -1, 0
    };
    PImage sharpen(PImage src, float[] ker, float strength) {
        int size=3;
        int r = size / 2;

        int w = src.width, h = src.height;
        src.loadPixels();
        
        PImage dst = createImage(w, h, ARGB);
        dst.loadPixels();
        
        for (int y = 0; y < h; y++) {
            int row = y * w;
            for (int x = 0; x < w; x++) {
                
              // --- center pixel (straight alpha) ---
                int c0 = src.pixels[row + x];
                int a0 = (c0 >>> 24) & 255;
                int r0 = (c0 >>> 16) & 255;
                int g0 = (c0 >>>  8) & 255;
                int b0 =  c0         & 255;
                
               // pre-multiplied center (0..255 range)
                float pr0 = r0 * (a0 / 255.0f);
                float pg0 = g0 * (a0 / 255.0f);
                float pb0 = b0 * (a0 / 255.0f);
                
              // --- convolution in PREMULTIPLIED space ---
                float pr =0, pg = 0, pb = 0;
                int ki = 0;
                
                for (int j= -r; j <= r; j++) {
                    int yy = clampInt(y + j, 0, h - 1);
                   int base = yy * w;
                    
                    for (int i =-r; i <= r; i++) {
                        int xx = clampInt(x + i, 0, w - 1);
                        int c = src.pixels[base + xx];
                        
                        int a = (c >>>24) & 255;
                        int rr = (c >>> 16) & 255;
                        int gg = (c >>>  8) & 255;
                        int bb =  c   & 255;
                        
                        float af = a /255.0f;
                        float weg = ker[ki++];
                        
                       // premultiplyneighbors before weighting
                       pr += (rr * af) * weg;
                       pg += (gg * af) * weg;
                       pb += (bb * af) * weg;
                    }
            }
                
              // --- adjustable strength: lerp in premultiplied space ---
               // outPremul = srcPremul + strength*(convPremul - srcPremul)
                float outPr = pr0 + strength * (pr - pr0);
                float outPg = pg0 + strength * (pg - pg0);
                float outPb = pb0 + strength * (pb - pb0);
                
              // --- output alpha: keep original (typical layer filter behavior) ---
                int outA =a0;
                
              // --- unpremultiply back to straight RGB ---
                int outR, outG, outB;
                if (outA >0) {
                    float invA =255.0f / outA;
                   outR = clamp255((int)(outPr * invA + 0.5f));
                   outG = clamp255((int)(outPg * invA + 0.5f));
                   outB = clamp255((int)(outPb * invA + 0.5f));
            } else{
                    outR = outG = outB = 0;
            }
                
                dst.pixels[row + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
            }
        }
        
        dst.updatePixels();
        return dst;
    }
}
