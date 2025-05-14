using GameZero #precisa do pacote Colors também, usar pkg. add Colors

#inicia a janela
WIDTH = 1280
HEIGHT = 720
BACKGROUND = colorant"antiquewhite"

fFrameTime = 1/30

#structtriangulo
mutable struct Triangulo
    pos::NamedTuple{(:x, :y),Tuple{Float64,Float64}}
    angle::Float64
    speed::Float64
end

# a forma que o Triangulo vai ter

const forma = [
    (0.0, -12.0),
    (8.0, 8.0),
    (-8.0, 8.0)
]

# Velocidade
speed = 3.0
rotation_speed = 3.0  # graus por frame
const iBoidNumber = 30 #numero de pasaros

# Cria triângulos em posições e ângulos aleatórios
function criar_triangulo()
    x = rand(50.0:750.0)
    y = rand(50.0:550.0)
    ang = rand(0.0:360.0)
    spd = rand(1.8:3.2)  # velocidade aleatória
    return Triangulo((x=x, y=y), ang, spd)
end

# Lista de triângulos
triangulos = [criar_triangulo() for _ in 1:iBoidNumber]

function transformar_forma(t::Triangulo)
    cosθ = cosd(t.angle)
    sinθ = sind(t.angle)
    return [(t.pos.x + x * cosθ - y * sinθ,                             # formula de rotação em um pontos
        t.pos.y + x * sinθ + y * cosθ) for (x, y) in forma]             # [x', y'] = [x * cos(θ) - y * sin(θ), x * sin(θ) + y * cos(θ)]
end

function draw_triangle!(triangle)
    x1, y1 = triangle[1]
    x2, y2 = triangle[2]
    x3, y3 = triangle[3]
    draw(Line(round(Int, x1), round(Int, y1), round(Int, x2), round(Int, y2)))  #não faz essa conversão automaticamente sem perda de precisão 
    draw(Line(round(Int, x2), round(Int, y2), round(Int, x3), round(Int, y3)))  #por segurança, lança um erro.
    draw(Line(round(Int, x3), round(Int, y3), round(Int, x1), round(Int, y1)))  #round(Int,v) evita isso
end

function calculateBoidsDistance(t1::Triangulo, t2::Triangulo)::Float64
    dx = t2.pos.x - t1.pos.x
    dy = t2.pos.y - t1.pos.y
    dd = sqrt(dx^2 + dy^2)
    return dd
    #return sqrt((t2.pos.x - t1.pos.x)^2 + (t2.pos.y - t1.pos.y)^2)  #pitagoras
end

function lerp(a, b, t)
    return a + t * (b - a)
end

function draw()

    for t in triangulos
        pontos = transformar_forma(t)       #atualiza posição e rotação
        draw_triangle!(pontos)             #desenha
    end
end

function update()

    for t in triangulos

        nearBoidsAngleX::Float64 = 0.0  #direção media
        nearBoidsAngleY::Float64 = 0.0
        tooNearBoidsAngleX::Float64 = 0.0   #vetor de fuga para evitar colizao
        tooNearBoidsAngleY::Float64 = 0.0
        nearBoidsNumber::Int = 0
        tooNearBoidsNumber::Int = 0

        for tt in triangulos
            if t !== tt && calculateBoidsDistance(t, tt) <= 80.0       #campo de visão onde ve boids proximos
                nearBoidsAngleX += cosd(tt.angle)
                nearBoidsAngleY += sind(tt.angle)
                nearBoidsNumber += 1

            end

            if t !== tt && calculateBoidsDistance(t, tt) <= 30.0       #distancia para colisoes
                tooNearBoidsAngleX += cosd(tt.angle)
                tooNearBoidsAngleY += sind(tt.angle)
                tooNearBoidsNumber += 1
            end
        end

        if nearBoidsNumber > 0
            avgAngleX = nearBoidsAngleX / nearBoidsNumber
            avgAngleY = nearBoidsAngleY / nearBoidsNumber
            avgAngle = atan(avgAngleY, avgAngleX) * 180 / π      # Converte o vetor médio de volta para um ângulo
            t.angle = lerp(t.angle, avgAngle, 0.05)
        end

        if tooNearBoidsNumber > 0
            avgAngleX = tooNearBoidsAngleX / tooNearBoidsNumber
            avgAngleY = tooNearBoidsAngleY / tooNearBoidsNumber
            avgAngle = atan((cosd(t.angle) - avgAngleY), (sind(t.angle) - avgAngleX)) * 180 / π      # Converte o vetor médio de volta para um ângulo
            t.angle = lerp(t.angle, (avgAngle / rand(0.4:0.9)), 0.05)
            #t.angle = avgAngle / (0.5 + (1.0 - 0.5) * rand()) # dividir para almentar a potencia da fuga  mas ideamente era pra ser baseado na distancia
        end

        t.speed = lerp(t.speed, rand(1.8:3.2), 0.01) # atualiza a velocidade e suaviza com lerp

        dx = sind(t.angle) * t.speed
        dy = -cosd(t.angle) * t.speed

        t.pos = (x=t.pos.x + dx, y=t.pos.y + dy)    #para TROCAR a POSIÇÃO TEM que trocar a tupla TODA


        # Verificar se o boid saiu da tela e teletransportá-lo para o lado oposto
        if t.pos.x < 0  # Se o boid sair pela borda esquerda
            t.pos = (x=WIDTH, y=t.pos.y)
        elseif t.pos.x > WIDTH  # Se o boid sair pela borda direita
            t.pos = (x=0, y=t.pos.y)
        end

        if t.pos.y < 0  # Se o boid sair pela borda superior
            t.pos = (x=t.pos.x, y=HEIGHT)
        elseif t.pos.y > HEIGHT  # Se o boid sair pela borda inferior
            t.pos = (x=t.pos.x, y=0)
        end
    end
    sleep(fFrameTime)
end


