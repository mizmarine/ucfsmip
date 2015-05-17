# 対象
class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end
end


class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        false
    end
end

class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "«#{self}»"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

# 演算子
class Add < Struct.new(:left,:right)
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment),right)
        elsif right.reducible?
            Add.new(left,right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end
end

class Multiply < Struct.new(:left,:right)
    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment),right)
        elsif right.reducible?
            Multiply.new(left,right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end
end

# 文
class DoNothing
    def to_s
        "do-nothing"
    end

    def inspect
        "<<#{self}>>"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
end

## 代入文
## 変数名 = 式
## 文は簡約文と環境のarrを返す
class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)),environment]
        else
            [DoNothing.new, environment.merge({name => expression})]
        end
    end
end

## IF文
## if 条件式 then 帰結文 else 代替文
class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if #{condition} then #{consequence} else #{alternative}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end


# 仮想機械
class Machine < Struct.new(:expression,:environment)
    def step
        self.expression = expression.reduce(environment)
    end

    def run
        while expression.reducible?
            puts expression
            step
        end
        puts expression
    end
end

class StatementMachine < Struct.new(:statement,:environment)
    def step
        self.statement, self.environment = statement.reduce(environment)
    end

    def run
        while statement.reducible?
            puts "#{statement}, #{environment}"
            step
        end
        puts "#{statement}, #{environment}"
    end
end



class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        environment[name]
    end
end


# 簡約計算
puts "1:加算"
exp = Add.new(
    Multiply.new(Number.new(1),Number.new(2)),
    Multiply.new(Number.new(3),Number.new(4))
)

env = {}
Machine.new(exp,env).run

puts "\n比較演算"
exp = LessThan.new(
    Number.new(5),
    Add.new(Number.new(2), Number.new(2))
)
Machine.new(exp,env).run


# 変数を使う
exp = Add.new(
    Variable.new(:x), Variable.new(:y)
)

env = {
    x: Number.new(3),
    y: Number.new(5)
}

puts "\n変数"
Machine.new(exp,env).run

# 文を扱う
puts "\n代入文"
state = Assign.new(
    :x, Add.new(Variable.new(:x), Number.new(1))
)

env = {
    x: Number.new(2)
}

StatementMachine.new(state, env).run

puts "\nif-else文"
state = If.new(
    Variable.new(:x),
    Assign.new(:y, Number.new(1)),
    Assign.new(:y, Number.new(2))
)

env = {
    x: Boolean.new(true)
}

StatementMachine.new(state, env).run

puts "\nif文"
state = If.new(
    Variable.new(:x),
    Assign.new(:y, Number.new(1)),
    DoNothing.new
)

env = {
    x: Boolean.new(false)
}

StatementMachine.new(state, env).run

